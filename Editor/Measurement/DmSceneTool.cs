// -----------------------------------------------------------------------------
//  Unity 工具箱 · 距离测量
//  DmSceneTool —— Scene 视图内的测量交互与空间 UI 绘制
//
//  交互（无显式模式，按落点几何自动判定类型）：
//    · 左键放置锚点：两个点 = 直线距离；三点及以上未闭合 = 折线（逐段长度 + 总长）
//    · 三点及以上时回到起点附近点一下（或按 Enter）即闭合，自动算每段长度、周长与面积（m²）
//    · 右键点一下「收工」：当前测量立即成为一条记录并留在场景里，视角继续可用
//    · 拖动已有测量的端点可微调；拖线段主体则整条平移
//    · Shift 正交（锁定到最近轴向） · Ctrl/Cmd 吸附已有端点
//    · Backspace 撤销上一点 · 右键 收工 · Esc 取消 / 再按退出
//  空间 UI：
//    · CAD 式尺寸线（深色衬底 + 主线 + 端部刻度 + 端点圆点）
//    · 圆角胶囊数值标签，屏幕恒定字号，永远清晰可读
//
//  性能约定（绘制路径上的三条硬规矩，改动时请勿破坏）：
//    1. 胶囊纹理按「分桶尺寸」缓存，绝不按精确宽高建纹理（见 DmSkin.DrawPill）
//    2. 像素↔世界比例用解析值 + 相机缓存，不要每次调用 GUIPointToWorldRay
//    3. Physics.Raycast 按「鼠标位置 + 相机是否变化」节流，不要每次 repaint 都打
// -----------------------------------------------------------------------------

using System;
using System.Collections.Generic;
using System.Globalization;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;

namespace CH.CustomTools.Measurement
{
    [InitializeOnLoad]
    internal static class DmSceneTool
    {
        const float CloseR = 22f;  // 面积闭合：光标距起点投影的屏幕像素阈值（略放宽，避免"差几像素点不中"）
        const string S = "CH.CustomTools.Measurement.Setting.";

        // ==================================================================
        //  设置项（EditorPrefs 持久化，跨会话保留）
        // ==================================================================
        public static event Action Changed;
        static void RaiseChanged() { if (Changed != null) Changed(); }

        // ---- 设置项在内存中缓存：场景绘制路径每帧都要读，不能每次去敲 EditorPrefs ----
        // 初值刻意与下方 LoadSettings 的 EditorPrefs 默认值保持一致：万一
        // LoadSettings 因故被中断（例如在禁止读 EditorPrefs 的构造路径上被调用），
        // 设置项不会静默退化成 false —— 那会直接表现为「表面吸附失效，
        // 光标永远落在 y=0 地平面上」。
        static bool _active;
        static bool _snapSurface = true, _snapGrid, _xray = true,
                    _showEndpoints = true, _showDelta = true, _showAngles = true;
        static int _gridStepIndex = 2, _decimals = 2;

        static void LoadSettings()
        {
            _active = false; // Input capture always requires an explicit enable in this session.
            _snapSurface = EditorPrefs.GetBool(S + "snapSurface", true);
            _snapGrid = EditorPrefs.GetBool(S + "snapGrid", false);
            _xray = EditorPrefs.GetBool(S + "xray", true);
            _showEndpoints = EditorPrefs.GetBool(S + "endpoints", true);
            _showDelta = EditorPrefs.GetBool(S + "delta", true);
            _showAngles = EditorPrefs.GetBool(S + "angles", true);
            _decimals = Mathf.Clamp(EditorPrefs.GetInt(S + "decimals", 2), 0, 4);

            _gridStepIndex = 2;
            float g = EditorPrefs.GetFloat(S + "gridStep", 0.25f);
            for (int i = 0; i < GridSteps.Length; i++)
            {
                if (Mathf.Approximately(GridSteps[i], g)) { _gridStepIndex = i; break; }
            }
        }

        public static bool Active
        {
            get { return _active; }
            set
            {
                if (_active == value) return;
                _active = value;
                _cursorCached = false;
                if (!value)
                {
                    ClearDraft();
                    EndDrag();
                }
                else
                {
                    // 每次启用都重建一次无碰撞体网格缓存：会话期间场景可能被改动过
                    // （移动/删除/新增扫描模型），沿用旧树会打到错误的表面。
                    DmSurface.Invalidate();
                }
                _hover = -1;
                _hoverPoint = -1;
                SceneView.RepaintAll();
                RaiseChanged();
            }
        }

        // ==================================================================
        //  无碰撞体网格拾取的状态与手动重建（面板用）
        //
        //  扫描模型常常没有 MeshCollider，Physics 打不中它们，射线只能靠
        //  DmSurface 自己算。面板显示这里的状态，用户就能一眼区分
        //  「索引没建」和「压根没这种网格」两种情况。
        // ==================================================================
        public static string SurfaceInfo
        {
            get
            {
                if (!DmSurface.IsBuilt) return DmText.Pick("移动鼠标后建立", "Built on cursor movement");
                int n = DmSurface.TriCount;
                if (n <= 0) return DmText.Pick("没有可用的可见网格", "No eligible visible meshes");
                // 显示构建耗时，让「首次移动鼠标那一下停顿」有个明确归因
                long ms = DmSurface.LastElapsedMs;
                return ms >= 100
                    ? n.ToString("N0") + DmText.Pick(" 三角形 · ", " triangles · ") + (ms / 1000.0).ToString("0.0") + " s"
                    : n.ToString("N0") + DmText.Pick(" 三角形", " triangles");
            }
        }

        public static void RebuildSurface()
        {
            if (!SnapSurface) SnapSurface = true;   // 关着吸附的话重建毫无意义
            DmSurface.Invalidate(true);             // 面板点了「重建」就一定要重来
            DmSurface.BuildNow();
            _cursorCached = false;
            SceneView.RepaintAll();
            RaiseChanged();
        }

        public static bool SnapSurface
        {
            get { return _snapSurface; }
            set
            {
                if (_snapSurface == value) return;
                _snapSurface = value;
                _cursorCached = false;
                EditorPrefs.SetBool(S + "snapSurface", value);
                RaiseChanged();
                SceneView.RepaintAll();
            }
        }

        public static bool SnapGrid
        {
            get { return _snapGrid; }
            set
            {
                if (_snapGrid == value) return;
                _snapGrid = value;
                EditorPrefs.SetBool(S + "snapGrid", value);
                RaiseChanged();
                SceneView.RepaintAll();
            }
        }

        static readonly float[] GridSteps = { 0.05f, 0.1f, 0.25f, 0.5f, 1f };
        public static readonly string[] GridStepNames = { "0.05 m", "0.1 m", "0.25 m", "0.5 m", "1 m" };

        public static int GridStepIndex
        {
            get { return _gridStepIndex; }
            set
            {
                int i = Mathf.Clamp(value, 0, GridSteps.Length - 1);
                if (i == _gridStepIndex) return;
                _gridStepIndex = i;
                EditorPrefs.SetFloat(S + "gridStep", GridSteps[i]);
                RaiseChanged();
                SceneView.RepaintAll();
            }
        }

        // 兜一层 Clamp：这是全包唯一未被保护的容器索引。
        // 当前取值路径都是有界的（setter 里 Clamp、LoadSettings 里由循环赋值），
        // 但绘制路径每帧都读它，一旦将来有人绕过 setter 直接改字段就会连片报错。
        public static float GridStep
        {
            get { return GridSteps[Mathf.Clamp(_gridStepIndex, 0, GridSteps.Length - 1)]; }
        }

        public static bool XRay
        {
            get { return _xray; }
            set
            {
                if (_xray == value) return;
                _xray = value;
                EditorPrefs.SetBool(S + "xray", value);
                RaiseChanged();
                SceneView.RepaintAll();
            }
        }

        public static bool ShowEndpoints
        {
            get { return _showEndpoints; }
            set
            {
                if (_showEndpoints == value) return;
                _showEndpoints = value;
                EditorPrefs.SetBool(S + "endpoints", value);
                RaiseChanged();
                SceneView.RepaintAll();
            }
        }

        public static bool ShowDelta
        {
            get { return _showDelta; }
            set
            {
                if (_showDelta == value) return;
                _showDelta = value;
                EditorPrefs.SetBool(S + "delta", value);
                RaiseChanged();
                SceneView.RepaintAll();
            }
        }

        public static bool ShowAngles
        {
            get { return _showAngles; }
            set
            {
                if (_showAngles == value) return;
                _showAngles = value;
                EditorPrefs.SetBool(S + "angles", value);
                RaiseChanged();
                SceneView.RepaintAll();
            }
        }

        /// <summary>数值小数位（0~4）。</summary>
        public static int Decimals
        {
            get { return _decimals; }
            set
            {
                int d = Mathf.Clamp(value, 0, 4);
                if (d == _decimals) return;
                _decimals = d;
                ClearFmtMemo();
                EditorPrefs.SetInt(S + "decimals", d);
                RaiseChanged();
                SceneView.RepaintAll();
            }
        }

        // ==================================================================
        //  会话状态
        // ==================================================================
        static readonly List<Vector3> _draft = new List<Vector3>();

        static Vector3 _cursor;
        // 本工具登记的默认控件 ID（AddDefaultControl 用）。
        // 登记后 Unity 会把 hotControl 指向它，所以落点门禁必须放行这个 ID，
        // 不能只认 hotControl == 0 —— 那会让整条左键交互链静默失效。
        static int _defaultControlId = -1;

        /// <summary>当前点击是否归本工具（可以落点/拖拽），而不是压在别的 gizmo 上。</summary>
        static bool CanAcceptClick
        {
            get
            {
                int hot = GUIUtility.hotControl;
                return hot == 0 || hot == _defaultControlId;
            }
        }

        static bool _cursorValid;

        static Vector2 _rmbDown;
        static bool _rmbMoved;

        static int _hover = -1;         // 悬停的测量索引
        static int _hoverPoint = -1;    // 悬停的顶点索引；-1 表示只悬停在线段上

        // ---- 拖拽状态 ----
        static bool _dragging;
        static int _dragEntry = -1;
        static int _dragPoint = -1;     // >= 0 拖单个顶点；-1 拖整条平移
        static Vector3 _dragStartWorld;
        static int _dragControlId;
        static readonly List<Vector3> _dragOriginPts = new List<Vector3>();

        public static bool HasDraft { get { return _draft.Count > 0; } }
        public static int DraftCount { get { return _draft.Count; } }
        public static bool IsDragging { get { return _dragging; } }

        static DmSceneTool()
        {
            LoadSettings();
            // 先 -= 再 +=，避免每次重编译后委托叠加，导致每帧把整屏重绘跑两遍（卡顿的根因）
            SceneView.duringSceneGui -= OnSceneGui;
            SceneView.duringSceneGui += OnSceneGui;
            DmStore.Changed -= SceneView.RepaintAll;
            DmStore.Changed += SceneView.RepaintAll;
            AssemblyReloadEvents.beforeAssemblyReload += OnReload;
            EditorApplication.quitting += OnReload;
            EditorApplication.hierarchyChanged += InvalidateSurface;
            SceneVisibilityManager.visibilityChanged += InvalidateSurface;
            Undo.undoRedoPerformed += InvalidateSurface;
            ObjectChangeEvents.changesPublished += OnObjectsChanged;
            DmStore.ContextChanging += ResetInteraction;
        }

        static void OnReload()
        {
            ResetInteraction(); DmStore.Flush(); DmSkin.ClearCache();
            SceneView.duringSceneGui -= OnSceneGui;
        }
        internal static void ResetInteraction()
        {
            EndDrag(); ClearDraft(); _hover=_hoverPoint=-1; _cursorCached=false;
            DmSurface.Invalidate(true);
        }
        static void InvalidateSurface() { DmSurface.Invalidate(true); _cursorCached=false; SceneView.RepaintAll(); }
        static void OnObjectsChanged(ref ObjectChangeEventStream stream)
        {
            for(int i=0;i<stream.length;i++)
            {
                if(stream.GetEventType(i)==ObjectChangeKind.ChangeGameObjectOrComponentProperties)
                {
                    ChangeGameObjectOrComponentPropertiesEventArgs change;
                    stream.GetChangeGameObjectOrComponentPropertiesEvent(i,out change);
                    var obj=EditorUtility.InstanceIDToObject(change.instanceId);
                    var component=obj as Component; var gameObject=obj as GameObject;
                    if(component!=null) gameObject=component.gameObject;
                    if(gameObject!=null && gameObject.scene.IsValid() && (gameObject.hideFlags & HideFlags.DontSave)==0) { InvalidateSurface(); return; }
                }
                else if(stream.GetEventType(i)==ObjectChangeKind.ChangeAssetObjectProperties)
                {
                    ChangeAssetObjectPropertiesEventArgs change;stream.GetChangeAssetObjectPropertiesEvent(i,out change);
                    if(EditorUtility.InstanceIDToObject(change.instanceId) is Mesh){InvalidateSurface();return;}
                }
            }
        }
        static void ClearDraft()
        {
            if (_draft.Count == 0) return;
            _draft.Clear();
            RaiseChanged();
            SceneView.RepaintAll();
        }

        /// <summary>供面板「取消当前测量」调用。</summary>
        public static void CancelDraft()
        {
            ClearDraft();
        }

        // ==================================================================
        //  主入口
        // ==================================================================
        /// <summary>
        /// Scene 主入口。外层包一层兜底：任何异常都不许打断 Scene 交互链 ——
        /// 事件拿不到 Use() 会连锁出「点击被当成落点」「GUIClip 不平衡」这类极难查的问题。
        /// </summary>
        static void OnSceneGui(SceneView sv)
        {
            try
            {
                OnSceneGuiCore(sv);
            }
            catch (System.Exception ex)
            {
                // 状态一律重置，避免半途中断留下卡死的拖拽/悬停
                _dragging = false;
                _dragEntry = -1;
                _dragPoint = -1;
                _hover = -1;
                _hoverPoint = -1;
                if (GUIUtility.hotControl == _dragControlId) GUIUtility.hotControl = 0;
                // 打完整堆栈而非一行 Message：Unity 控制台不给堆栈帧，
                // 只有「Index was out of range」无法归因到具体是哪一个索引。
                Debug.LogWarning("[CH Scene measurement] Scene interaction failed; tool state reset.\n" + ex);
            }
        }

        static void OnSceneGuiCore(SceneView sv)
        {
            if (sv == null || sv.camera == null) return;
            Camera cam = sv.camera;
            Event e = Event.current;

            if (Active)
            {
                SolveCursor(cam);
                HandleInput(cam, e);
            }
            else
            {
                if (_dragging) EndDrag();
                _hover = -1;
                _hoverPoint = -1;
            }

            // 只在 Repaint 阶段真正画：Scene 视图每帧会派发 Layout / MouseMove / KeyDown 等
            // 多种事件，若每种事件都画一遍，标签的 CalcSize / 富文本解析 / 画线会重复执行
            // 2~3 次，是绘制路径上最大的浪费（卡顿主因之一）。
            if (e != null && e.type == EventType.Repaint)
            {
                DrawEntries(cam);
                DrawDraft(cam);
                Handles.zTest = CompareFunction.LessEqual;
            }

            // Scene 视图是按需重绘的：鼠标移动本身不一定触发 Repaint，预览会"慢半拍"。
            // 激活测量时鼠标一动就主动要求重绘，光标预览才能实时跟随。
            // 重绘内容本来就要画，几乎没有额外开销。
            if (Active && e != null && e.type == EventType.MouseMove)
                sv.Repaint();
        }

        // ==================================================================
        //  光标落点解算
        //
        //  Physics.Raycast 是这条路径上最贵的一步，而 Scene 视图每次 repaint 都会
        //  走进来（包括键盘、布局等与鼠标无关的事件）。所以按
        //  「鼠标位置 + 相机位姿」做缓存：两者都没变就直接复用上次的落点。
        // ==================================================================
        static Vector2 _cursorScreen;
        static Vector3 _cursorCamPos;
        static Quaternion _cursorCamRot;
        static bool _cursorCached;
        static Camera _cursorCamera;
        static Matrix4x4 _cursorProjection;
        static Rect _cursorPixelRect;
        static int _cursorMask;

        static void SolveCursor(Camera cam)
        {
            if (Event.current == null) return;

            Vector2 mp = Event.current.mousePosition;
            Transform ct = cam.transform;

            if (_cursorCached && _cursorCamera==cam && _cursorProjection==cam.projectionMatrix && _cursorPixelRect==cam.pixelRect && _cursorMask==cam.cullingMask && mp == _cursorScreen &&
                ct.position == _cursorCamPos && ct.rotation == _cursorCamRot)
                return;

            _cursorCamera=cam;_cursorProjection=cam.projectionMatrix;_cursorPixelRect=cam.pixelRect;_cursorMask=cam.cullingMask;
            _cursorScreen = mp;
            _cursorCamPos = ct.position;
            _cursorCamRot = ct.rotation;
            _cursorCached = true;

            _cursorValid = false;
            Ray ray = HandleUtility.GUIPointToWorldRay(mp);

            if (SnapSurface && TrySurface(ray, cam.cullingMask, out _cursor)) { _cursorValid=true; return; }

            // 3) 兜底：Unity 参考网格平面（y = 0）
            var plane = new Plane(Vector3.up, Vector3.zero);
            float dist;
            if (plane.Raycast(ray, out dist))
            {
                _cursor = ray.GetPoint(dist);
                _cursorValid = true;
            }
        }

        internal static bool TrySurface(Ray ray, int mask, out Vector3 point)
        {
            if(DmSurface.LayerMask!=mask){DmSurface.LayerMask=mask;DmSurface.Invalidate(true);}
            Physics.SyncTransforms(); float nearest=100000f;bool found=false;point=Vector3.zero;
            foreach(var hit in Physics.RaycastAll(ray,nearest,mask,QueryTriggerInteraction.Ignore))
                if(hit.distance<nearest && DmSurface.Visible(hit.collider.gameObject)){nearest=hit.distance;point=hit.point;found=true;}
            Vector3 meshHit;
            if(DmSurface.TryHit(ray,nearest,out meshHit)){point=meshHit;found=true;}
            return found;
        }
        /// <summary>在原始落点上叠加 正交 / 网格 / 端点吸附。</summary>
        /// <param name="skipEntry">吸附时要跳过的测量（拖拽自身时避免吸附到自己身上）。</param>
        /// <param name="skipIndex">要跳过的顶点索引。</param>
        static Vector3 ResolvePoint(Camera cam, Vector3 raw, Vector3 anchor, bool hasAnchor,
            MeasureEntry skipEntry = null, int skipIndex = -1)
        {
            Event e = Event.current;
            Vector3 p = raw;

            bool freeX = true, freeY = true, freeZ = true;

            if (hasAnchor && e != null && e.shift)
            {
                Vector3 d = p - anchor;
                float ax = Mathf.Abs(d.x), ay = Mathf.Abs(d.y), az = Mathf.Abs(d.z);
                if (ax >= ay && ax >= az) { p.y = anchor.y; p.z = anchor.z; freeY = freeZ = false; }
                else if (ay >= az) { p.x = anchor.x; p.z = anchor.z; freeX = freeZ = false; }
                else { p.x = anchor.x; p.y = anchor.y; freeX = freeY = false; }
            }

            if (SnapGrid && GridStep > 0.0001f)
            {
                float g = GridStep;
                if (freeX) p.x = Mathf.Round(p.x / g) * g;
                if (freeY) p.y = Mathf.Round(p.y / g) * g;
                if (freeZ) p.z = Mathf.Round(p.z / g) * g;
            }

            if (hasAnchor && e != null && (e.control || e.command))
            {
                Vector3 snap;
                if (TrySnapEndpoint(cam, p, skipEntry, skipIndex, out snap)) p = snap;
            }

            return p;
        }

        static bool TrySnapEndpoint(Camera cam, Vector3 p, MeasureEntry skipEntry, int skipIndex,
            out Vector3 result)
        {
            result = p;
            const float threshold = 14f;

            Vector2 sp;
            if (!TryProject(cam, p, out sp)) return false;

            float best = threshold;
            var list = DmStore.Entries;
            for (int i = 0; i < list.Count; i++)
            {
                var en = list[i];
                var pts = en == null ? null : en.points;
                if (pts == null) continue;
                for (int j = 0; j < pts.Count; j++)
                {
                    if (en == skipEntry && j == skipIndex) continue;
                    Vector2 ps;
                    if (!TryProject(cam, pts[j], out ps)) continue;
                    float d = Vector2.Distance(sp, ps);
                    if (d < best) { best = d; result = pts[j]; }
                }
            }
            return best < threshold;
        }

        // ==================================================================
        //  输入
        // ==================================================================
        static void HandleInput(Camera cam, Event e)
        {
            if (e == null) return;

            // Allocate the same control in each event; register it as default only during Layout.
            _defaultControlId=GUIUtility.GetControlID("CH.Scene.Measurement".GetHashCode(),FocusType.Passive);
            if (e.type == EventType.Layout) HandleUtility.AddDefaultControl(_defaultControlId);
            if(GUIUtility.hotControl!=0 && GUIUtility.hotControl!=_defaultControlId && GUIUtility.hotControl!=_dragControlId) return;

            // ---------------- 键盘 ----------------
            if (e.type == EventType.KeyDown)
            {
                if (e.keyCode == KeyCode.Escape)
                {
                    // 分层退出：正在画的先取消，再按一次才退出测量模式
                    if (_draft.Count > 0) ClearDraft();
                    else Active = false;
                    e.Use();
                    return;
                }
                if (e.keyCode == KeyCode.Return || e.keyCode == KeyCode.KeypadEnter)
                {
                    // Enter = 收工；若光标已回到起点附近（≥3 点）则闭合为面积
                    Vector2 ss;
                    CommitDraft(NearStartPoint(cam, out ss));
                    e.Use();
                    return;
                }
                if (e.keyCode == KeyCode.Backspace || e.keyCode == KeyCode.Delete)
                {
                    if (_draft.Count > 0)
                    {
                        _draft.RemoveAt(_draft.Count - 1);
                        RaiseChanged();
                        SceneView.RepaintAll();
                    }
                    e.Use();
                    return;
                }
            }

            // ---------------- 右键：点一下「收工」，拖动则是转视角 ----------------
            if (e.type == EventType.MouseDown && e.button == 1)
            {
                _rmbDown = e.mousePosition;
                _rmbMoved = false;
            }
            else if (e.type == EventType.MouseDrag && e.button == 1)
            {
                if ((e.mousePosition - _rmbDown).sqrMagnitude > 36f) _rmbMoved = true;
            }
            else if (e.type == EventType.MouseUp && e.button == 1 && !_rmbMoved)
            {
                if (_draft.Count > 0)
                {
                    // 收工：提交成记录留在场景里。若光标已回到起点附近（≥3 点）则闭合为面积，否则按几何判为直线/折线
                    Vector2 ss;
                    CommitDraft(NearStartPoint(cam, out ss));
                    e.Use();
                }
                return;
            }

            // ---------------- 正在拖拽 ----------------
            if (_dragging)
            {
                if (e.type == EventType.MouseUp && e.button == 0)
                {
                    EndDrag();
                    e.Use();
                    return;
                }
                if (e.type == EventType.MouseDrag || e.type == EventType.MouseMove ||
                    e.type == EventType.Repaint)
                    ApplyDrag(cam);
                return;
            }

            if (e.type == EventType.MouseMove || e.type == EventType.MouseDrag || e.type == EventType.MouseDown)
                UpdateHover(cam, e.mousePosition);

            // hotControl 压在别的 gizmo 手柄上时不落点。注意：不能写成 hotControl == 0，
            // AddDefaultControl 之后 hotControl 就是自己的控件 ID（非 0），那样门禁恒为假。
            if (e.type == EventType.MouseDown && e.button == 0 && !e.alt &&
                CanAcceptClick && HandleUtility.nearestControl==_defaultControlId && _cursorValid)
            {
                // 回到起点附近点一下即闭合（最后一笔不重复落点）。闭合优先于拖拽已有测量，
                // 否则「在已有测量旁边圈地」时容易误触发拖拽而圈不拢。
                Vector2 startScreen;
                if (NearStartPoint(cam, out startScreen))
                {
                    CommitDraft(true);
                    e.Use();
                    return;
                }

                // 命中已有测量 → 拖拽调整。顶点命中总是优先；
                // 只压到线段时，若正在画新的就别抢（避免干扰落点）。
                bool canDrag = _hoverPoint >= 0 || _draft.Count == 0;
                if (_hover >= 0 && canDrag && BeginDrag())
                {
                    e.Use();
                    return;
                }

                Vector3 anchor = _draft.Count > 0 ? _draft[_draft.Count - 1] : Vector3.zero;
                Vector3 p = ResolvePoint(cam, _cursor, anchor, _draft.Count > 0);
                PlacePoint(p);
                e.Use();
            }
        }

        static void PlacePoint(Vector3 p)
        {
            if (_draft.Count > 0 && Vector3.Distance(_draft[_draft.Count - 1], p) < 0.0005f) return;

            _draft.Add(p);

            RaiseChanged();
            SceneView.RepaintAll();
        }

        /// <summary>光标回到起点附近（≥3 点）则返回 true，并输出起点屏幕坐标。</summary>
        static bool NearStartPoint(Camera cam, out Vector2 startScreen)
        {
            startScreen = Vector2.zero;
            if (_draft.Count < 3 || Event.current == null || !_cursorValid) return false;
            if (!TryProject(cam, _draft[0], out startScreen)) return false;
            return Vector2.Distance(startScreen, Event.current.mousePosition) < CloseR;
        }

        /// <summary>
        /// 把当前草稿提交为一条测量记录。
        /// asArea = true 表示已闭合（回到起点），记录为面积；否则按几何判为直线或折线。
        /// </summary>
        static void CommitDraft(bool asArea = false)
        {
            if (_draft.Count < 2)
            {
                ClearDraft();
                return;
            }

            var en = new MeasureEntry();
            en.points = new List<Vector3>(_draft);
            en.Dedupe();

            if (en.points.Count < 2 || (asArea && en.points.Count < 3))
            {
                ClearDraft();
                return;
            }

            if(asArea)
            {
                double area;string reason;
                if(!DmGeometry.TryArea(en.points,out area,out reason)){if(SceneView.lastActiveSceneView!=null)SceneView.lastActiveSceneView.ShowNotification(new GUIContent(reason));return;}
            }
            // kind 必须随 Add 一起传进去：Add 内部新建记录，事后改局部 en 不会生效
            DmStore.Add(en.points, NextColor(), asArea ? MeasureKind.Area : MeasureKind.Length);

            _draft.Clear();

            RaiseChanged();
            SceneView.RepaintAll();
        }

        static Color NextColor()
        {
            return DmSkin.Palette[DmStore.Count % DmSkin.Palette.Length];
        }

        // ==================================================================
        //  悬停判定：先找顶点，找不到再退到线段
        // ==================================================================
        static void UpdateHover(Camera cam, Vector2 mp)
        {
            const float VertexR = 13f;   // 顶点命中半径（屏幕像素）
            const float SegR = 9f;

            // 测量记录可能在别处被删掉（面板删除按钮、清除本场景数据），
            // 悬停/拖拽里缓存的是**索引**，不清就会越界。
            ValidateHover();

            int bestEntry = -1, bestPoint = -1;
            var list = DmStore.Entries;

            float bestV = VertexR * VertexR;
            for (int i = 0; i < list.Count; i++)
            {
                var en = list[i];
                if (en == null || !en.visible || en.points == null || en.points.Count < 2) continue;

                for (int j = 0; j < en.points.Count; j++)
                {
                    Vector2 sp;
                    if (!TryProject(cam, en.points[j], out sp)) continue;
                    float d = (sp - mp).sqrMagnitude;
                    if (d < bestV) { bestV = d; bestEntry = i; bestPoint = j; }
                }
            }

            if (bestEntry < 0)
            {
                float bestD = SegR;
                for (int i = 0; i < list.Count; i++)
                {
                    var en = list[i];
                    if (en == null || !en.visible || en.points == null || en.points.Count < 2) continue;

                    for (int j = 0; j < en.points.Count - 1; j++)
                    {
                        Vector2 a, b;
                        if (!TryProject(cam, en.points[j], out a)) continue;
                        if (!TryProject(cam, en.points[j + 1], out b)) continue;
                        float d = ScreenDistToSegment(mp, a, b);
                        if (d < bestD) { bestD = d; bestEntry = i; }
                    }
                }
            }

            if (bestEntry != _hover || bestPoint != _hoverPoint)
            {
                _hover = bestEntry;
                _hoverPoint = bestPoint;
                SceneView.RepaintAll();
            }
        }

        /// <summary>
        /// 修正悬停/拖拽里缓存的**索引**：记录被删除后旧索引会越界，
        /// 直接拿去 List[i] 取值就是 ArgumentOutOfRangeException。
        /// 悬停/拖拽的生命期以 cursor/数据变化为界，这里只做自愈清空。
        /// </summary>
        static void ValidateHover()
        {
            var list = DmStore.Entries;
            if (_hover >= 0 && _hover < list.Count)
            {
                var en = list[_hover];
                if (en != null && en.points != null && (_hoverPoint < 0 || _hoverPoint < en.points.Count))
                    return;   // 仍然有效
            }
            _hover = -1;
            _hoverPoint = -1;
            if (_dragEntry >= list.Count) EndDrag();
        }

        static float ScreenDistToSegment(Vector2 p, Vector2 a, Vector2 b)
        {
            Vector2 ab = b - a;
            float l2 = ab.sqrMagnitude;
            if (l2 < 0.0001f) return Vector2.Distance(p, a);
            float t = Mathf.Clamp01(Vector2.Dot(p - a, ab) / l2);
            return Vector2.Distance(p, a + ab * t);
        }

        // ==================================================================
        //  拖拽已有测量：顶点微调 / 整条平移
        // ==================================================================
        static bool BeginDrag()
        {
            var list = DmStore.Entries;
            if (_hover < 0 || _hover >= list.Count || !_cursorValid) return false;

            var en = list[_hover];
            if (en == null || en.points == null || en.points.Count < 2) return false;

            _dragging = true;
            _dragEntry = _hover;
            _dragPoint = _hoverPoint;          // -1 = 拖整条
            _dragStartWorld = _cursor;
            _dragOriginPts.Clear();
            _dragOriginPts.AddRange(en.points);

            // 占住 hotControl，Unity 才不会把这次拖拽当成框选
            DmStore.RecordUndo("Move measurement");
            _dragControlId = _defaultControlId;
            GUIUtility.hotControl = _dragControlId;
            SceneView.RepaintAll();
            return true;
        }

        static void ApplyDrag(Camera cam)
        {
            var list = DmStore.Entries;
            if (_dragEntry < 0 || _dragEntry >= list.Count) { EndDrag(); return; }

            var en = list[_dragEntry];
            if (en == null || en.points == null || en.points.Count == 0) { EndDrag(); return; }
            if (!_cursorValid) return;

            if (_dragPoint >= 0)
            {
                if (_dragPoint >= en.points.Count) { EndDrag(); return; }

                // 以相邻点为基准：Shift 沿轴约束、Ctrl 吸附别的端点都以它作参照
                Vector3 anchor = _dragPoint > 0
                    ? en.points[_dragPoint - 1]
                    : (_dragPoint + 1 < en.points.Count ? en.points[_dragPoint + 1] : en.points[_dragPoint]);

                en.points[_dragPoint] = ResolvePoint(cam, _cursor, anchor, true, en, _dragPoint);
            }
            else
            {
                Vector3 delta = _cursor - _dragStartWorld;
                if (SnapGrid && GridStep > 0.0001f)
                {
                    float g = GridStep;
                    delta = new Vector3(
                        Mathf.Round(delta.x / g) * g,
                        Mathf.Round(delta.y / g) * g,
                        Mathf.Round(delta.z / g) * g);
                }

                int n = Mathf.Min(en.points.Count, _dragOriginPts.Count);
                for (int i = 0; i < n; i++) en.points[i] = _dragOriginPts[i] + delta;
            }

            DmStore.Raise();          // 拖拽过程中只刷新界面，不写盘
            SceneView.RepaintAll();
        }

        static void EndDrag()
        {
            if (!_dragging) return;

            _dragging = false;
            _dragEntry = -1;
            _dragPoint = -1;
            _dragOriginPts.Clear();
            // Release only this tool's control; another tool may have taken ownership.
            if(GUIUtility.hotControl == _dragControlId) GUIUtility.hotControl = 0;
            _dragControlId = 0;

            DmStore.NotifyEdited();   // 拖完了才落盘
            SceneView.RepaintAll();
        }

        // ==================================================================
        //  绘制：已有测量
        // ==================================================================
        static void DrawEntries(Camera cam)
        {
            var list = DmStore.Entries;
            Handles.zTest = XRay ? CompareFunction.Always : CompareFunction.LessEqual;

            for (int i = 0; i < list.Count; i++)
            {
                var en = list[i];
                if (en == null || !en.visible) continue;
                if (en.points == null || en.points.Count < 2) continue;
                DrawEntry(cam, en, i == _hover, i == _hover ? _hoverPoint : -1);
            }

            Handles.zTest = CompareFunction.LessEqual;
        }

        static void DrawEntry(Camera cam, MeasureEntry en, bool hot, int hotPoint)
        {
            Color c = en.color;
            Color main = new Color(c.r, c.g, c.b, hot ? 1f : 0.9f);

            var pts = en.points;

            if (en.kind == MeasureKind.Area)
            {
                DrawAreaFill(cam, pts, c);
                for (int i = 0; i < pts.Count - 1; i++)
                    DrawDimensionLine(cam, pts[i], pts[i + 1], main, hot);
                DrawDimensionLine(cam, pts[pts.Count - 1], pts[0], main, hot); // 闭合边
            }
            else
            {
                for (int i = 0; i < pts.Count - 1; i++)
                    DrawDimensionLine(cam, pts[i], pts[i + 1], main, hot);
            }

            // 端点统一在外面画：内部点不再被相邻两段各画一次
            if (ShowEndpoints)
            {
                for (int i = 0; i < pts.Count; i++)
                {
                    bool focus = i == hotPoint;
                    DrawAnchor(cam, pts[i], c, PixelToWorld(cam, pts[i], focus ? 4.8f : 3.2f),
                        true, hot || focus);

                    if (focus)
                    {
                        // 再套一圈外环，明确提示"这个点可以拖"
                        Handles.color = new Color(c.r, c.g, c.b, 0.55f);
                        Handles.DrawWireDisc(pts[i], -cam.transform.forward,
                            PixelToWorld(cam, pts[i], 11f), 1.5f);
                    }
                }
            }

            // Angles are the smaller included angle, including at concave polygon vertices.
            if (ShowAngles && pts.Count >= 3)
            {
                if (en.kind == MeasureKind.Area)
                {
                    for (int i = 0; i < pts.Count; i++)
                        DrawAngleMark(cam, pts[(i + pts.Count - 1) % pts.Count], pts[i],
                            pts[(i + 1) % pts.Count], c, hot && i == hotPoint);
                }
                else
                {
                    for (int i = 1; i < pts.Count - 1; i++)
                        DrawAngleMark(cam, pts[i - 1], pts[i], pts[i + 1], c, hot && i == hotPoint);
                }
            }

            if (en.kind == MeasureKind.Area)
            {
                int n = pts.Count;
                // 闭合面：每段长度逐段标注（含闭合边），再给周长 + 面积
                for (int i = 0; i < n; i++)
                {
                    int j = (i + 1) % n;
                    DrawSegLabel(cam, pts[i], pts[j], Vector3.Distance(pts[i], pts[j]), c, false, -1f);
                }
                DrawAreaLabel(cam, en, hot);
            }
            else
            {
                int segments = pts.Count - 1;
                if (segments == 1)
                {
                    DrawSegLabel(cam, pts[0], pts[1], Vector3.Distance(pts[0], pts[1]), c, hot, 1f);
                }
                else
                {
                    // 折线：段数不多时逐段标注，否则只保留总长，避免画面变噪
                    if (segments <= 3)
                    {
                        for (int i = 0; i < segments; i++)
                            DrawSegLabel(cam, pts[i], pts[i + 1], Vector3.Distance(pts[i], pts[i + 1]), c, false, -1f);
                    }
                    DrawTotalLabel(cam, en, hot);
                }
            }
        }

        static void DrawAreaFill(Camera cam, List<Vector3> pts, Color c)
        {
            if (pts == null || pts.Count < 3) return;
            double area;string reason;
            if(!DmGeometry.TryArea(pts,out area,out reason))return;
            CompareFunction prevZ = Handles.zTest;
            Color prevCol = Handles.color;
            Handles.zTest = CompareFunction.Always;
            Handles.color = new Color(c.r, c.g, c.b, 0.16f);
            // 耳切三角化：凹多边形也能正确填充（不会填到凹口外）。
            // 每个三角形以 4 点凸多边形绘制（末点复用一次），填充色取当前 Handles.color。
            var tris = Triangulate(pts);
            if (tris != null)
            {
                for (int i = 0; i + 2 < tris.Count; i += 3)
                    Handles.DrawAAConvexPolygon(pts[tris[i]], pts[tris[i + 1]], pts[tris[i + 2]], pts[tris[i + 2]]);
            }
            Handles.zTest = prevZ;
            Handles.color = prevCol;
        }

        // ==================================================================
        //  耳切三角化（Ear Clipping）
        //
        //  把多边形投影到法线主轴垂直的平面上做 2D 三角化，返回顶点索引三元组。
        //  对手工测量的简单多边形（含凹多边形）正确；自交等异常情况返回 null。
        // ==================================================================
        static List<int> Triangulate(List<Vector3> pts)
        {
            int n = pts.Count;
            if (n < 3) return null;
            if (n == 3) return new List<int> { 0, 1, 2 };

            // Newell 法求法线，选绝对值最大的轴，投影到另两个轴张成的平面
            Vector3 nrm = Vector3.zero;
            for (int i = 0; i < n; i++)
            {
                Vector3 a = pts[i]-pts[0], b = pts[(i + 1) % n]-pts[0];
                nrm.x += (a.y - b.y) * (a.z + b.z);
                nrm.y += (a.z - b.z) * (a.x + b.x);
                nrm.z += (a.x - b.x) * (a.y + b.y);
            }
            float ax = Mathf.Abs(nrm.x), ay = Mathf.Abs(nrm.y), az = Mathf.Abs(nrm.z);

            var p2 = new Vector2[n];
            for (int i = 0; i < n; i++)
            {
                var p=pts[i]-pts[0];
                if (ax >= ay && ax >= az) p2[i] = new Vector2(p.y, p.z);
                else if (ay >= az) p2[i] = new Vector2(p.x, p.z);
                else p2[i] = new Vector2(p.x, p.y);
            }

            // 鞋带公式判朝向，统一成逆时针（signed > 0 表示顺时针，需要倒序）
            float signed = 0f;
            for (int i = 0; i < n; i++)
            {
                Vector2 u = p2[i], v = p2[(i + 1) % n];
                signed += (v.x - u.x) * (v.y + u.y);
            }
            var idx = new List<int>(n);
            for (int i = 0; i < n; i++) idx.Add(signed > 0f ? n - 1 - i : i);

            var tris = new List<int>((n - 2) * 3);
            int guard = 0;
            while (idx.Count > 3 && guard++ < 4096)
            {
                bool earFound = false;
                for (int i = 0; i < idx.Count; i++)
                {
                    int i0 = idx[(i + idx.Count - 1) % idx.Count];
                    int i1 = idx[i];
                    int i2 = idx[(i + 1) % idx.Count];
                    Vector2 a = p2[i0], b = p2[i1], c = p2[i2];

                    if (Cross2(a, b, c) <= 1e-9f) continue;   // 凹角或退化，不是耳朵

                    bool contains = false;
                    for (int j = 0; j < idx.Count; j++)
                    {
                        int k = idx[j];
                        if (k == i0 || k == i1 || k == i2) continue;
                        if (PointInTriangle(p2[k], a, b, c)) { contains = true; break; }
                    }
                    if (contains) continue;

                    tris.Add(i0); tris.Add(i1); tris.Add(i2);
                    idx.RemoveAt(i);
                    earFound = true;
                    break;
                }
                if (!earFound) return null;   // 找不到耳朵 = 多边形异常（自交等）
            }
            if (idx.Count == 3) { tris.Add(idx[0]); tris.Add(idx[1]); tris.Add(idx[2]); }
            return tris;
        }

        static float Cross2(Vector2 a, Vector2 b, Vector2 c)
        {
            return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
        }

        static bool PointInTriangle(Vector2 p, Vector2 a, Vector2 b, Vector2 c)
        {
            return Cross2(a, b, p) >= -1e-9f && Cross2(b, c, p) >= -1e-9f && Cross2(c, a, p) >= -1e-9f;
        }

        static void DrawAreaLabel(Camera cam, MeasureEntry en, bool hot)
        {
            Vector3 c = Vector3.zero;
            for (int i = 0; i < en.points.Count; i++) c += en.points[i];
            c /= en.points.Count;

            Vector2 sp;
            if (!TryProject(cam, c, out sp)) return;
            float area=en.Area();

            _scratch.text = "<color=#" + DmSkin.Hex(DmSkin.SceneUnitText) + ">"+DmText.Pick("周长 ","Perimeter ")+"</color>"
                          + "<color=#" + DmSkin.Hex(DmSkin.Ink(en.color)) + ">" + Fmt(en.TotalLength()) + "</color>"
                          + "<color=#" + DmSkin.Hex(DmSkin.SceneUnitText) + "> m · "+DmText.Pick("面积 ","Area ")+"</color>"
                          + "<color=#" + DmSkin.Hex(DmSkin.Ink(en.color)) + ">" + (float.IsNaN(area)?DmText.Pick("无效边界","Invalid boundary"):Fmt(area)) + "</color>"
                          + "<color=#" + DmSkin.Hex(DmSkin.SceneUnitText) + "> m²</color>";

            DrawPillGui(new Vector2(sp.x, sp.y - 20f), _scratch, en.color, hot, DmSkin.SceneValueStyle, DmSkin.TextPrimary);
        }

        /// <summary>CAD 式尺寸线：深色衬底 + 主线 + 端部刻度。端点圆点由调用方统一绘制。</summary>
        static void DrawDimensionLine(Camera cam, Vector3 a, Vector3 b, Color col, bool hot)
        {
            Vector3 dir = b - a;
            if (dir.sqrMagnitude < 1e-8f) return;
            dir.Normalize();

            CHSceneVisuals.Line(col, hot, a, b);

            Vector3 perp = Vector3.Cross(dir, cam.transform.forward);
            if (perp.sqrMagnitude < 1e-6f) perp = Vector3.Cross(dir, Vector3.up);
            perp.Normalize();

            float tick = PixelToWorld(cam, (a + b) * 0.5f, 9f);
            Handles.color = col;
            Handles.DrawAAPolyLine(2f, a - perp * tick, a + perp * tick);
            Handles.DrawAAPolyLine(2f, b - perp * tick, b + perp * tick);
        }

        static void DrawAnchor(Camera cam, Vector3 p, Color col, float r, bool solid, bool ring)
        {
            CHSceneVisuals.Anchor(cam, p, col, r, solid, ring);
        }

        // ==================================================================
        //  角度标注：顶点处的圆弧 + 度数标签
        // ==================================================================
        static void DrawAngleMark(Camera cam, Vector3 prev, Vector3 vtx, Vector3 next, Color c, bool hot)
        {
            Vector3 d1=prev-vtx,d2=next-vtx;float deg;
            if(!DmGeometry.TryAngle(prev,vtx,next,out deg))return;
            Vector3 nrm=Vector3.Cross(d1,d2);float r=PixelToWorld(cam,vtx,15f);
            Handles.color=new Color(c.r,c.g,c.b,hot?.95f:.65f);
            if(nrm.sqrMagnitude>1e-10f) Handles.DrawWireArc(vtx,nrm.normalized,d1.normalized,deg,r,1.5f);
            Vector3 bis=d1.normalized+d2.normalized;
            if(bis.sqrMagnitude<1e-6f)bis=Vector3.Cross(d1.normalized,cam.transform.forward);
            if(bis.sqrMagnitude<1e-6f)bis=Vector3.Cross(d1.normalized,cam.transform.up);
            Vector3 lp=vtx+bis.normalized*(r*1.7f);

            Vector2 sp;
            if (!TryProject(cam, lp, out sp)) return;

            _scratch.text = "<color=#" + DmSkin.Hex(DmSkin.Ink(c)) + ">"
                          + deg.ToString("F1", CultureInfo.InvariantCulture) + "°</color>";
            DrawPillGui(sp, _scratch, c, false, DmSkin.SceneMetaStyle, DmSkin.TextPrimary);
        }

        // ==================================================================
        //  绘制：正在进行的测量
        // ==================================================================
        static void DrawDraft(Camera cam)
        {
            if (_draft.Count == 0) return;

            Color col = DmSkin.Accent;
            var soft = new Color(col.r, col.g, col.b, 0.62f);

            // 三点及以上时，光标是否回到起点附近（出现即表示可闭合为面积）
            bool nearStart = false;
            Vector2 startScreen = Vector2.zero;
            nearStart = NearStartPoint(cam, out startScreen);

            Handles.zTest = CompareFunction.Always;

            for (int i = 0; i < _draft.Count - 1; i++)
            {
                Handles.color = DmSkin.SceneHalo;
                Handles.DrawAAPolyLine(4.5f, _draft[i], _draft[i + 1]);
                Handles.color = soft;
                Handles.DrawAAPolyLine(2f, _draft[i], _draft[i + 1]);
            }

            // 即将闭合时的实时填充：与闭合后的填充同一套耳切三角化，凹多边形也不会填错
            if (nearStart && _draft.Count >= 3)
            {
                CompareFunction prevZ = Handles.zTest;
                Color prevCol = Handles.color;
                Handles.zTest = CompareFunction.Always;
                Handles.color = new Color(col.r, col.g, col.b, 0.16f);
                var tris = Triangulate(_draft);
                if (tris != null)
                {
                    for (int i = 0; i + 2 < tris.Count; i += 3)
                        Handles.DrawAAConvexPolygon(_draft[tris[i]], _draft[tris[i + 1]], _draft[tris[i + 2]], _draft[tris[i + 2]]);
                }
                else
                {
                    for (int i = 1; i < _draft.Count - 1; i++)
                        Handles.DrawAAConvexPolygon(_draft[0], _draft[i], _draft[i + 1], _draft[i + 1]);
                }
                Handles.zTest = prevZ;
                Handles.color = prevCol;
            }

            for (int i = 0; i < _draft.Count; i++)
                DrawAnchor(cam, _draft[i], col, PixelToWorld(cam, _draft[i], 3.4f), true, i == 0);

            // 角度：已确定的中间拐点各画一个；末点与光标之间的预览角也实时给出
            if (ShowAngles && _draft.Count >= 2)
            {
                for (int i = 1; i < _draft.Count - 1; i++)
                    DrawAngleMark(cam, _draft[i - 1], _draft[i], _draft[i + 1], col, false);
            }

            if (!_cursorValid) return;

            Vector3 last = _draft[_draft.Count - 1];
            Vector3 target = ResolvePoint(cam, _cursor, last, true);
            if (nearStart) target = _draft[0];

            if (ShowAngles && _draft.Count >= 2)
                DrawAngleMark(cam, _draft[_draft.Count - 2], last, target, col, true);

            Vector3 delta = target - last;

            // 沿轴分解的虚线：直观看出 X / Y / Z 各贡献多少
            if (ShowDelta && delta.sqrMagnitude > 1e-6f)
            {
                Vector3 flat = new Vector3(target.x, last.y, target.z);
                if (Vector3.Distance(flat, last) > 0.001f && Vector3.Distance(flat, target) > 0.001f)
                {
                    Handles.color = new Color(col.r, col.g, col.b, 0.30f);
                    Handles.DrawDottedLine(last, flat, 4f);
                    Handles.color = new Color(col.r, col.g, col.b, 0.46f);
                    Handles.DrawDottedLine(flat, target, 4f);
                }
            }

            Handles.color = DmSkin.SceneHalo;
            Handles.DrawAAPolyLine(4.5f, last, target);
            Handles.color = new Color(col.r, col.g, col.b, 0.85f);
            Handles.DrawAAPolyLine(2f, last, target);

            DrawCursorMark(cam, target, col);

            // 实时读数 + 分量读数
            DrawSegLabel(cam, last, target, delta.magnitude, col, true, 1f);

            // 回到起点附近：提示「闭合」
            if (nearStart && startScreen != Vector2.zero)
            {
                _scratch.text = "<color=#" + DmSkin.Hex(DmSkin.Ink(col)) + ">"+DmText.Pick("闭合", "Close area")+"</color>";
                DrawPillGui(new Vector2(startScreen.x, startScreen.y - 18f), _scratch, col, true, DmSkin.SceneMetaStyle, DmSkin.TextPrimary);
            }

            if (ShowDelta)
            {
                // 用 side = -1 取线下方的那条法线，分量读数才能稳稳落在线的另一侧
                Vector2 below;
                if (SegLabelAnchor(cam, last, target, -1f, out below))
                {
                    _scratch.text = "<color=#" + DmSkin.Hex(DmSkin.SceneDimText) + ">X </color>"
                                  + "<color=#" + DmSkin.Hex(DmSkin.TextPrimary) + ">" + Fmt(delta.x) + "</color>"
                                  + "<color=#" + DmSkin.Hex(DmSkin.SceneDimText) + ">   Y </color>"
                                  + "<color=#" + DmSkin.Hex(DmSkin.TextPrimary) + ">" + Fmt(delta.y) + "</color>"
                                  + "<color=#" + DmSkin.Hex(DmSkin.SceneDimText) + ">   Z </color>"
                                  + "<color=#" + DmSkin.Hex(DmSkin.TextPrimary) + ">" + Fmt(delta.z) + "</color>";
                    DrawPillGui(below, _scratch, col, false, DmSkin.SceneMetaStyle, DmSkin.SceneDimText);
                }
            }
        }

        /// <summary>光标处的十字准星，提示"正在放置"。</summary>
        static void DrawCursorMark(Camera cam, Vector3 p, Color col)
        {
            Vector3 n = -cam.transform.forward;
            float r = PixelToWorld(cam, p, 3.0f);
            float arm = PixelToWorld(cam, p, 8.0f);

            Handles.color = col;
            Handles.DrawWireDisc(p, n, r * 1.7f, 1.5f);

            Vector3 up = cam.transform.up * arm;
            Vector3 right = cam.transform.right * arm;

            Handles.color = new Color(col.r, col.g, col.b, 0.8f);
            Handles.DrawAAPolyLine(1.5f, p - right, p + right);
            Handles.DrawAAPolyLine(1.5f, p - up, p + up);
        }

        // ==================================================================
        //  空间 UI：数值胶囊标签
        //
        //  所有标签共用同一个 GUIContent 临时对象：CalcSize 与 Label 都是立即完成的，
        //  同一帧内复用安全，省掉每帧每个标签一次托管分配。
        // ==================================================================
        static readonly GUIContent _scratch = new GUIContent();

        static string ValueText(float meters, Color accent)
        {
            return "<color=#" + DmSkin.Hex(DmSkin.Ink(accent)) + ">" + Fmt(meters) + "</color>"
                 + "<color=#" + DmSkin.Hex(DmSkin.SceneUnitText) + "> m</color>";
        }

        static string TotalText(float meters, Color accent)
        {
            return "<color=#" + DmSkin.Hex(DmSkin.SceneUnitText) + ">"+DmText.Pick("总 ","Total ")+"</color>"
                 + "<color=#" + DmSkin.Hex(DmSkin.Ink(accent)) + ">" + Fmt(meters) + "</color>"
                 + "<color=#" + DmSkin.Hex(DmSkin.SceneUnitText) + "> m</color>";
        }

        /// <summary>把标签锚点摆到线的屏幕法线方向，保证不与线重叠。</summary>
        static bool SegLabelAnchor(Camera cam, Vector3 a, Vector3 b, float side, out Vector2 anchor)
        {
            anchor = Vector2.zero;
            Vector2 sa, sb;
            if (!TryProject(cam, a, out sa)) return false;
            if (!TryProject(cam, b, out sb)) return false;

            Vector2 dir = sb - sa;
            if (dir.sqrMagnitude < 0.0001f) dir = Vector2.right;
            dir.Normalize();

            Vector2 nrm = new Vector2(-dir.y, dir.x);
            if (nrm.y > 0f) nrm = -nrm;   // 让法线始终朝屏幕上方

            anchor = (sa + sb) * 0.5f + nrm * (18f * side);
            return true;
        }

        static void DrawSegLabel(Camera cam, Vector3 a, Vector3 b, float meters, Color accent, bool strong, float side)
        {
            Vector2 anchor;
            if (!SegLabelAnchor(cam, a, b, side, out anchor)) return;

            _scratch.text = ValueText(meters, accent);

            DrawPillGui(anchor, _scratch, accent, strong, DmSkin.SceneValueStyle, DmSkin.TextPrimary);
        }

        static void DrawTotalLabel(Camera cam, MeasureEntry en, bool hot)
        {
            Vector2 sp;
            if (!TryProject(cam, en.ArcMidpoint(), out sp)) return;

            _scratch.text = TotalText(en.TotalLength(), en.color);

            DrawPillGui(new Vector2(sp.x, sp.y - 20f), _scratch, en.color, hot, DmSkin.SceneValueStyle, DmSkin.TextPrimary);
        }

        /// <summary>
        /// 进入 Scene 视图的 2D GUI 作用域绘制一枚胶囊标签。
        /// **必须**用 try/finally 保证 Begin/EndGUI 配对：一旦中间抛异常（例如索引越界），
        /// 漏掉 EndGUI 会报 "You are pushing more GUIClips than you are popping"，
        /// 并让之后的 Scene 事件链跟着出问题（点击不响应、状态卡住）。
        /// </summary>
        static Rect DrawPillGui(Vector2 center, GUIContent content, Color accent, bool strong,
            GUIStyle style, Color textColor)
        {
            return CHSceneVisuals.Pill(center, content, accent, strong, style, textColor);
        }

        // ==================================================================
        //  工具方法
        // ==================================================================
        // 数值格式化带记忆化：绘制路径上每帧都要格式化好多个数值，
        // 同值直接复用字符串，省掉大量短命托管分配。
        const int FmtSlots = 8;
        static readonly float[] _fmtVal = new float[FmtSlots];
        static readonly string[] _fmtStr = new string[FmtSlots];
        static int _fmtSlot;

        static void ClearFmtMemo()
        {
            for (int i = 0; i < FmtSlots; i++) _fmtStr[i] = null;
        }

        public static string Fmt(float meters)
        {
            for (int i = 0; i < FmtSlots; i++)
            {
                if (_fmtStr[i] != null && _fmtVal[i] == meters) return _fmtStr[i];
            }

            string s = meters.ToString("F" + _decimals, CultureInfo.InvariantCulture);
            _fmtVal[_fmtSlot] = meters;
            _fmtStr[_fmtSlot] = s;
            _fmtSlot = (_fmtSlot + 1) % FmtSlots;
            return s;
        }

        /// <summary>世界坐标 → Scene 视图 GUI 坐标；不可见时返回 false。</summary>
        static bool TryProject(Camera cam, Vector3 world, out Vector2 gui)
        {
            gui = Vector2.zero;
            Vector3 vp = cam.WorldToViewportPoint(world);
            if (vp.z <= 0.01f) return false;
            if (vp.x < -1.5f || vp.x > 2.5f || vp.y < -1.5f || vp.y > 2.5f) return false;
            gui = HandleUtility.WorldToGUIPoint(world);
            return true;
        }

        // ------------------------------------------------------------------
        //  像素 ↔ 世界 比例
        //
        //  端部刻度、端点圆点、准星的尺寸都要换算成世界长度，才能做到屏幕尺寸恒定。
        //  原实现每次调用都做两次 HandleUtility.GUIPointToWorldRay（内含矩阵求逆），
        //  而绘制一帧要算十几次 —— 这是绘制路径上的主要开销。
        //
        //  改成：只在相机变化时探测一次「深度 1 处 1 像素等于多少世界长度」，
        //  透视相机下该值随深度严格线性，所以任意点直接按深度缩放即可，结果与
        //  原实现一致。
        // ------------------------------------------------------------------
        static Camera _p2wCam;
        static Vector3 _p2wCamPos;
        static Quaternion _p2wCamRot;
        static float _p2wPerDepth;
        static bool _p2wValid;

        static float MeasurePixelWorld(Camera cam, Vector3 world, float pixels)
        {
            Vector2 sp = HandleUtility.WorldToGUIPoint(world);
            float depth = Vector3.Dot(world - cam.transform.position, cam.transform.forward);
            if (depth < 0.001f) depth = 0.001f;

            Vector3 a = HandleUtility.GUIPointToWorldRay(sp).GetPoint(depth);
            Vector3 b = HandleUtility.GUIPointToWorldRay(sp + new Vector2(pixels, 0f)).GetPoint(depth);
            return Vector3.Distance(a, b);
        }

        static void RefreshPixelScale(Camera cam)
        {
            Transform t = cam.transform;
            if (_p2wValid && _p2wCam == cam && _p2wCamPos == t.position && _p2wCamRot == t.rotation)
                return;

            _p2wCam = cam;
            _p2wCamPos = t.position;
            _p2wCamRot = t.rotation;
            _p2wValid = true;

            // 在相机正前方 1 个深度单位处探测
            _p2wPerDepth = MeasurePixelWorld(cam, t.position + t.forward, 1f);
        }

        static float PixelToWorld(Camera cam, Vector3 world, float pixels)
        {
            RefreshPixelScale(cam);
            if (cam.orthographic) return pixels * _p2wPerDepth;   // 正交：与深度无关

            float depth = Vector3.Dot(world - cam.transform.position, cam.transform.forward);
            if (depth < 0.001f) depth = 0.001f;
            return pixels * depth * _p2wPerDepth;
        }
    }
}
