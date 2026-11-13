// -----------------------------------------------------------------------------
//  Unity 工具箱 · 距离测量
//  DmSurface —— 无碰撞体网格的射线求交（扫描模型专用）
//
//  为什么要这个文件：
//    交互原本只用 Physics.Raycast 定位光标，而 PhysX 只认识 **Collider**。
//    扫描模型通常只有 MeshFilter + MeshRenderer（美术/扫描管线不会顺带挂
//    MeshCollider，几十万三角形挂 collider 也很贵），于是射线必然 miss，
//    SolveCursor 退化为 y=0 参考地平面 —— 表现就是「只能在地平面上测量」。
//
//  对当前编辑 Stage 的可见 MeshFilter + MeshRenderer 建立三角形索引，
//  包括已有 Collider 的网格；与 Physics 命中距离比较，选择最近表面。
//
//  BVH 参数与修建经验（照搬遮罩生成器 MaskBuilder 的成熟实现，勿轻易改）：
//    · 叶节点 8 三角形；按包围盒最长轴取 **质心中位数** 二分（Array.Sort）
//    · 建树 O(n log n)；**禁止**手写 partition + 冒泡兜底 —— 那在几十万个
//      近共面三角形上会退化成 O(n²)，实测卡死 40 分钟
//    · 用显式栈迭代（不用递归），避免深树爆栈
//    · Mesh.GetTriangles(List<int>) 在部分 Unity 版本 DLL 里不存在，统一用
//      m.GetTriangles(buf, s) 的 List 重载（本项目 2022.3.10f1 实测可用）
// -----------------------------------------------------------------------------

using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;

namespace CH.CustomTools.Measurement
{
    internal sealed class DmSurface
    {
        Vector3[] _verts;
        int[] _tris;
        int[] _triOrder;
        Vector3[] _centroid;
        Node[] _nodes;

        struct Node
        {
            public Vector3 bmin, bmax;
            public int start, count;
            public int left, right;
        }

        public int TriangleCount { get { return _tris == null ? 0 : _tris.Length / 3; } }

        // 产品路径用 Build()（自动从场景收集）；
        // 这个 internal 构造给离线测试用（测试与本包编进同一程序集），
        // 让「BVH 不漏检」这条最关键的几何性质能进自动化验证，而不用碰场景。
        internal DmSurface(Vector3[] verts, int[] tris)
        {
            _verts = verts;
            _tris = tris;
            BuildBVH();
        }

        // ==================================================================
        //  单例访问：惰性构建，避免一进 Scene 就为整个场景建树
        // ==================================================================
        static DmSurface _inst;
        internal static int LayerMask = ~0;
        static bool _built;

        static bool _mustRebuild;   // true = 下次构建无视指纹，一定重建

        /// <summary>
        /// 让下次射线重新核对索引。注意：这里**不直接丢弃**已建好的树 ——
        /// 扫描模型动辄六七十万三角形，重建要 1～2 秒，
        /// 原来「每次启用工具都重建」会让每次开启都要干等一下。
        /// 现改为按场景指纹判断：结构没变就复用。
        /// </summary>
        public static void Invalidate() { _built = false; }

        /// <summary>强制下次重建（面板「重建」按钮用）。</summary>
        public static void Invalidate(bool force)
        {
            _built = false;
            if (force) _mustRebuild = true;
        }

        public static bool IsBuilt { get { return _built; } }
        public static bool IsReady { get { return _built && _inst != null && _inst.TriangleCount > 0; } }
        public static int TriCount { get { return _inst == null ? 0 : _inst.TriangleCount; } }

        /// <summary>立刻建立索引（面板「重建」按钮用），不再等第一次射线。</summary>
        public static void BuildNow()
        {
            _built = true;

            // 复用判定：场景指纹没变就直接沿用旧树，省掉 1～2 秒的重建停顿
            long fp = ComputeFingerprint();
            if (_inst != null && !_mustRebuild && fp == _fingerprint)
            {
                Debug.Log("[CH Scene measurement] Reused mesh index: " + _inst.TriangleCount + " triangles.");
                return;
            }
            _mustRebuild = false;
            _fingerprint = fp;

            var sw = System.Diagnostics.Stopwatch.StartNew();
            _meshCount = _skipCollider = _badTris = 0;
            _inst = Build();
            sw.Stop();
            _elapsedMs = sw.ElapsedMilliseconds;

            // 这一行是排查「为什么量不到扫描模型」的关键依据，所以**总是**打，
            // 不再只在耗时较长时打：万一一个人推断另一个人改坏了。
            int tris = _inst == null ? 0 : _inst.TriangleCount;
            Debug.Log("[CH Scene measurement] Mesh index: "+_meshCount+" meshes / "+tris+" triangles / "+_skipCollider+" excluded / "+_badTris+" rejected triangles / "+_elapsedMs+" ms.");
        }

        static int _meshCount, _skipCollider, _badTris;
        static long _elapsedMs;
        static long _fingerprint;

        /// <summary>
        /// 场景指纹：网格数量 + 各网格实例 ID + 其世界矩阵。
        /// 覆盖「增删物体 / 换网格 / 移动 / 旋转 / 缩放」——任何会让缓存失效的改动。
        /// 只遍历根节点层级的变换，不碰顶点数据，因此开销远小于重建。
        /// </summary>
        static long ComputeFingerprint()
        {
            unchecked
            {
                long h = unchecked((long)0xcbf29ce484222325UL);   // FNV 偏移基
                var filters = Object.FindObjectsByType<MeshFilter>(FindObjectsSortMode.InstanceID);
                h = (h * 1099511628211L) ^ filters.Length;

                for (int i = 0; i < filters.Length; i++)
                {
                    var mf = filters[i];
                    if (mf == null || mf.sharedMesh == null) continue;
                    Transform t = mf.transform;
                    if (!t.gameObject.activeInHierarchy) continue;
                    if (!Eligible(t.gameObject) || (LayerMask & (1 << t.gameObject.layer)) == 0) continue;

                    h = (h * 1099511628211L) ^ mf.sharedMesh.GetInstanceID();
                    Matrix4x4 m = t.localToWorldMatrix;
                    for (int c = 0; c < 16; c++)
                        h = (h * 1099511628211L) ^ m[c].GetHashCode();
                }
                return h;
            }
        }

        /// <summary>上一次构建耗时（ms），面板可显示给用户看。</summary>
        public static long LastElapsedMs { get { return _elapsedMs; } }

        /// <summary>Mesh intersection bounded by the nearest eligible Physics hit.</summary>
        public static bool TryHit(Ray ray, float maxDist, out Vector3 hit)
        {
            hit = Vector3.zero;
            if (!_built)
                BuildNow();                    // 只尝试构建一次：场景真没网格就别反复扫
            if (_inst == null || _inst.TriangleCount == 0) return false;
            return _inst.Raycast(ray.origin, ray.direction, maxDist, out hit) > 0f;
        }

        // ==================================================================
        //  Collect eligible visible static meshes in the current editing Stage.
        // ==================================================================
        internal static bool Eligible(GameObject obj)
        {
            if(obj==null || !obj.activeInHierarchy || !obj.scene.IsValid() || !obj.scene.isLoaded) return false;
            var renderer=obj.GetComponent<MeshRenderer>();
            return renderer!=null && renderer.enabled && !SceneVisibilityManager.instance.IsHidden(obj) && StageUtility.GetStageHandle(obj)==StageUtility.GetCurrentStageHandle();
        }
        internal static bool Visible(GameObject obj)
        {
            return obj!=null && obj.activeInHierarchy && obj.scene.IsValid() && obj.scene.isLoaded && !SceneVisibilityManager.instance.IsHidden(obj) && StageUtility.GetStageHandle(obj)==StageUtility.GetCurrentStageHandle();
        }
        static DmSurface Build()
        {
            var vlist = new List<Vector3>(65536);
            var tlist = new List<int>(98304);

            // 只收 Scene 里启用的网格。SkinnedMeshRenderer 不处理：
            // 它的顶点受骨骼驱动，用绑定姿势换算会给出错误的距离读数，宁缺勿滥。
            var filters = Object.FindObjectsByType<MeshFilter>(FindObjectsSortMode.InstanceID);
            for (int i = 0; i < filters.Length; i++)
            {
                var mf = filters[i];
                if (mf == null || mf.sharedMesh == null) continue;
                Transform t = mf.transform;
                if (!t.gameObject.activeInHierarchy) continue;
                if (!Eligible(t.gameObject) || (LayerMask & (1 << t.gameObject.layer)) == 0) { _skipCollider++; continue; }

                try
                {
                    _badTris += Collect(t, mf.sharedMesh, vlist, tlist);
                    _meshCount++;
                }
                catch (System.Exception ex)
                {
                    // 单个网格读不出来不能拖垮整份索引；其余网格照常参与拾取。
                    // 打完整堆栈：控制台不给堆栈帧时只有一行 Message 无法定位。
                    Debug.LogWarning("[CH Scene measurement] Skipped unreadable mesh " + t.name + ":\n" + ex);
                }
            }

            if (tlist.Count == 0) return null;

            // 走 internal 构造（内部已含 BuildBVH），不要写成对象初始化器：
            // 带参构造存在时编译器不再生成无参构造，初始化器语法会报 CS7036。
            return new DmSurface(vlist.ToArray(), tlist.ToArray());
        }

        /// <summary>返回被丢弃的坏三角形数量（索引越界 + 退化），供调用方统计上报。</summary>
        static int Collect(Transform t, Mesh m, List<Vector3> vlist, List<int> tlist)
        {
            int bad = 0;
            int sub = m.subMeshCount;
            if (sub <= 0) sub = 1;
            Vector3[] local = m.vertices;
            if (local == null || local.Length == 0) return 0;

            Matrix4x4 mat = t.localToWorldMatrix;
            int baseIdx = vlist.Count;
            for (int i = 0; i < local.Length; i++)
                vlist.Add(mat.MultiplyPoint(local[i]));

            var buf = new List<int>(1024);
            for (int s = 0; s < sub; s++)
            {
                buf.Clear();
                if (m.GetTopology(s) != MeshTopology.Triangles) continue;
                m.GetTriangles(buf, s);
                for (int k = 0; k + 2 < buf.Count; k += 3)
                {
                    int ia = buf[k], ib = buf[k + 1], ic = buf[k + 2];

                    // 索引校验：某些导出/扫描数据里存在「索引越界的三角形」。
                    // 直接拿去 List<> 取值会抛 ArgumentOutOfRangeException("index")，
                    // 而这是 Scene 绘制路径上的热点，一抛就是连片报错 + GUIClip 失衡。
                    // 坏三角形丢掉即可，不能让整份网格的拾取跟着失效。
                    if (ia < 0 || ia >= local.Length ||
                        ib < 0 || ib >= local.Length ||
                        ic < 0 || ic >= local.Length)
                    { bad++; continue; }

                    int a = baseIdx + ia, b = baseIdx + ib, c = baseIdx + ic;
                    // 退化三角形（面积≈0）同样丢弃，省得 BVH 里塞垃圾
                    if (Vector3.Cross(vlist[b] - vlist[a], vlist[c] - vlist[a]).sqrMagnitude < 1e-12f)
                    { bad++; continue; }
                    tlist.Add(a); tlist.Add(b); tlist.Add(c);
                }
            }
            return bad;
        }

        // ==================================================================
        //  BVH 构建：中位数二分 + 迭代（与 MaskBuilder.ScanSurface 同款，已实测 60 万三角形 ≈1.7s）
        // ==================================================================
        void BuildBVH()
        {
            int n = _tris.Length / 3;
            if (n == 0) { _triOrder = new int[0]; _nodes = new Node[0]; return; }

            _triOrder = new int[n];
            _centroid = new Vector3[n];
            for (int i = 0; i < n; i++)
            {
                _triOrder[i] = i;
                _centroid[i] = (_verts[_tris[i * 3]] + _verts[_tris[i * 3 + 1]] + _verts[_tris[i * 3 + 2]]) / 3f;
            }

            var nodes = new List<Node>(n / 4 + 16);
            nodes.Add(new Node { start = 0, count = n, left = -1, right = -1 });

            var stack = new List<int>(256);
            stack.Add(0);

            float[] sortKey = new float[n];

            while (stack.Count > 0)
            {
                int ni = stack[stack.Count - 1];
                stack.RemoveAt(stack.Count - 1);
                Node node = nodes[ni];

                Vector3 bmin = new Vector3(float.MaxValue, float.MaxValue, float.MaxValue);
                Vector3 bmax = new Vector3(float.MinValue, float.MinValue, float.MinValue);
                for (int k = node.start; k < node.start + node.count; k++)
                {
                    int t = _triOrder[k];
                    for (int c = 0; c < 3; c++)
                    {
                        Vector3 p = _verts[_tris[t * 3 + c]];
                        bmin = Vector3.Min(bmin, p);
                        bmax = Vector3.Max(bmax, p);
                    }
                }
                node.bmin = bmin; node.bmax = bmax;

                if (node.count <= 8) { node.left = -1; node.right = -1; nodes[ni] = node; continue; }

                Vector3 ext = bmax - bmin;
                int axis = ext.x >= ext.y && ext.x >= ext.z ? 0 : (ext.y >= ext.z ? 1 : 2);
                for (int k = node.start; k < node.start + node.count; k++)
                {
                    Vector3 c = _centroid[_triOrder[k]];
                    sortKey[k] = axis == 0 ? c.x : (axis == 1 ? c.y : c.z);
                }
                System.Array.Sort(sortKey, _triOrder, node.start, node.count);

                int mid = node.start + node.count / 2;
                int l = nodes.Count;
                nodes.Add(new Node { start = node.start, count = mid - node.start, left = -1, right = -1 });
                int r = nodes.Count;
                nodes.Add(new Node { start = mid, count = node.start + node.count - mid, left = -1, right = -1 });
                node.left = l; node.right = r;
                nodes[ni] = node;
                stack.Add(l); stack.Add(r);
            }

            _nodes = nodes.ToArray();
        }

        // ==================================================================
        //  查询
        // ==================================================================
        /// <summary>最近正向命中距离；无命中返回 -1。</summary>
        public float Raycast(Vector3 origin, Vector3 dir, float maxDist, out Vector3 hit)
        {
            hit = Vector3.zero;
            if (_nodes == null || _nodes.Length == 0) return -1f;

            float best = maxDist;
            bool found = false;
            Vector3 bestHit = Vector3.zero;
            RaycastNode(0, origin, dir, ref best, ref found, ref bestHit);
            if (found) { hit = bestHit; return best; }
            return -1f;
        }

        void RaycastNode(int ni, Vector3 o, Vector3 d, ref float best, ref bool found, ref Vector3 bestHit)
        {
            Node node = _nodes[ni];
            if (!RayAABB(o, d, node.bmin, node.bmax, best)) return;

            if (node.left < 0)
            {
                for (int k = node.start; k < node.start + node.count; k++)
                {
                    int t = _triOrder[k];
                    Vector3 a = _verts[_tris[t * 3]], b = _verts[_tris[t * 3 + 1]], c = _verts[_tris[t * 3 + 2]];
                    float dist;
                    if (RayTri(o, d, a, b, c, out dist) && dist < best)
                    {
                        best = dist; found = true; bestHit = o + d * dist;
                    }
                }
            }
            else
            {
                RaycastNode(node.left, o, d, ref best, ref found, ref bestHit);
                RaycastNode(node.right, o, d, ref best, ref found, ref bestHit);
            }
        }

        static bool RayAABB(Vector3 o, Vector3 d, Vector3 bmin, Vector3 bmax, float maxDist)
        {
            float tmin = -maxDist, tmax = maxDist;
            for (int i = 0; i < 3; i++)
            {
                float dn = d[i];
                float mn = bmin[i] - o[i];
                float mx = bmax[i] - o[i];
                if (Mathf.Abs(dn) < 1e-8f)
                {
                    if (mn > 0f || mx < 0f) return false;
                }
                else
                {
                    float inv = 1f / dn;
                    float t1 = mn * inv, t2 = mx * inv;
                    if (t1 > t2) { float tmp = t1; t1 = t2; t2 = tmp; }
                    tmin = Mathf.Max(tmin, t1);
                    tmax = Mathf.Min(tmax, t2);
                    if (tmin > tmax) return false;
                }
            }
            return tmax >= 0f;
        }

        /// <summary>Möller–Trumbore 射线-三角形求交（只认正面朝这边的三角形指向由绕序决定，双面）。</summary>
        public static bool RayTri(Vector3 o, Vector3 d, Vector3 a, Vector3 b, Vector3 c, out float dist)
        {
            dist = -1f;
            Vector3 e1 = b - a, e2 = c - a;
            Vector3 p = Vector3.Cross(d, e2);
            float det = Vector3.Dot(e1, p);
            if (Mathf.Abs(det) < 1e-9f) return false;
            float inv = 1f / det;
            Vector3 tt = o - a;
            float u = Vector3.Dot(tt, p) * inv;
            if (u < -1e-6f || u > 1f + 1e-6f) return false;
            Vector3 q = Vector3.Cross(tt, e1);
            float v = Vector3.Dot(d, q) * inv;
            if (v < -1e-6f || u + v > 1f + 1e-6f) return false;
            float t = Vector3.Dot(e2, q) * inv;
            if (t < 1e-5f) return false;
            dist = t;
            return true;
        }
    }
}
