// -----------------------------------------------------------------------------
//  Unity 工具箱 · 距离测量
//  DmSkin —— 视觉令牌（Design Tokens）与自绘 UI 基元
//
//  设计基调：
//    · 参数面板 → 完全沿用 Unity 编辑器的皮肤语义色，做到"看起来就像 Unity 自带工具"
//    · 场景空间 UI → 自绘圆角胶囊 / 尺寸线 / 端部刻度，做到"简约、克制、有设计感"
// -----------------------------------------------------------------------------

using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools.Measurement
{
    internal static class DmSkin
    {
        public static bool Pro { get { return EditorGUIUtility.isProSkin; } }

        static Color C(string hex)
        {
            Color c;
            ColorUtility.TryParseHtmlString("#" + hex, out c);
            return c;
        }

        // ------------------------------------------------------------------
        //  面板语义色（跟随皮肤）
        //  这些令牌在每帧绘制路径上被高频读取，故整体缓存，仅在皮肤变化时重建
        // ------------------------------------------------------------------
        static bool _cachePro;
        static bool _cacheValid;
        static Color _textPrimary, _textSecondary, _textMuted, _divider, _switchOff, _panelBg;
        static Color _pillBg, _pillShadow, _unitText, _dimText, _halo;

        static void EnsureCache()
        {
            bool pro = EditorGUIUtility.isProSkin;
            if (_cacheValid && _cachePro == pro) return;
            _cachePro = pro;
            _cacheValid = true;

            _textPrimary = pro ? C("D7D7D7") : C("202020");
            _textSecondary = pro ? C("9B9B9B") : C("565656");
            _textMuted = pro ? C("787878") : C("8C8C8C");
            _divider = pro ? C("2A2A2A") : C("B2B2B2");
            _switchOff = pro ? C("4B4B4B") : C("ABABAB");
            _panelBg = pro ? C("383838") : C("C9C9C9");

            _pillBg = pro ? new Color(0.082f, 0.082f, 0.082f, 0.88f) : new Color(0.976f, 0.976f, 0.976f, 0.95f);
            _pillShadow = new Color(0f, 0f, 0f, pro ? 0.50f : 0.22f);
            _unitText = pro ? C("8E8E8E") : C("6B6B6B");
            _dimText = pro ? C("868686") : C("6E6E6E");
            _halo = new Color(0f, 0f, 0f, pro ? 0.38f : 0.20f);
        }

        public static Color TextPrimary { get { EnsureCache(); return _textPrimary; } }
        public static Color TextSecondary { get { EnsureCache(); return _textSecondary; } }
        public static Color TextMuted { get { EnsureCache(); return _textMuted; } }
        public static Color Divider { get { EnsureCache(); return _divider; } }
        public static Color SwitchOff { get { EnsureCache(); return _switchOff; } }
        public static Color PanelBg { get { EnsureCache(); return _panelBg; } }

        // ------------------------------------------------------------------
        //  测量配色 —— 场景内 3D 与空间 UI 共用
        //  明暗两种皮肤下均保持足够对比度；刻意避开 Unity 三轴红绿蓝
        // ------------------------------------------------------------------
        public static readonly Color[] Palette =
        {
            C("FFB648"), // 琥珀
            C("3FD8E0"), // 湖蓝
            C("5BD98A"), // 薄荷
            C("FF7A6B"), // 珊瑚
            C("B58CFF"), // 紫罗兰
            C("FF8FC2"), // 玫红
        };

        public static readonly string[] PaletteName = { "琥珀", "湖蓝", "薄荷", "珊瑚", "紫罗兰", "玫红" };

        public static Color Accent { get { return Palette[0]; } }
        public static Color AccentSoft { get { return new Color(Palette[0].r, Palette[0].g, Palette[0].b, 0.22f); } }

        /// <summary>
        /// 强调色 → 文字用墨色。
        /// 深色皮肤直接使用原色；浅色皮肤下按明度压暗，保证在近白胶囊底上仍有足够对比度。
        /// </summary>
        public static Color Ink(Color accent)
        {
            if (Pro) return accent;
            float lum = 0.299f * accent.r + 0.587f * accent.g + 0.114f * accent.b;
            return Color.Lerp(accent, Color.black, lum > 0.55f ? 0.42f : 0.18f);
        }

        // ------------------------------------------------------------------
        //  场景空间 UI 令牌
        // ------------------------------------------------------------------
        public const float PillRadius = 6f;
        public const float PillBorder = 1f;
        public const float LabelFontSize = 11f;
        public const float MetaFontSize = 10f;

        public static Color ScenePillBg { get { EnsureCache(); return _pillBg; } }
        public static Color ScenePillShadow { get { EnsureCache(); return _pillShadow; } }
        public static Color SceneUnitText { get { EnsureCache(); return _unitText; } }
        public static Color SceneDimText { get { EnsureCache(); return _dimText; } }
        public static Color SceneHalo { get { EnsureCache(); return _halo; } }

        /// <summary>把强调色按不同亮度混入当前皮肤背景，用于面板中的高亮块。</summary>
        public static Color Tint(Color accent, float amount)
        {
            EnsureCache();
            return Color.Lerp(_panelBg, accent, amount);
        }

        // ------------------------------------------------------------------
        //  圆角胶囊纹理（SDF 生成：1px 抗锯齿描边 + 柔和投影）
        //
        //  ⚠ 性能关键：纹理尺寸必须"分桶量化"后再缓存，不能用精确宽高当缓存键。
        //
        //  原因：实时读数每帧都在跳数字，标签宽度跟着变。若按精确宽高做键，
        //  每帧都会未命中 → 重建一张 SDF 纹理（逐像素浮点运算 + SetPixels32 数组
        //  分配 + GPU 上传），再叠加缓存淘汰时的 DestroyImmediate，测量过程中会
        //  持续掉帧。把宽度对齐到 8px、高度对齐到 4px 后，整段拖拽里最多只建几张。
        //
        //  绘制时纹理仍被拉伸到真实尺寸，宽度偏差 < 8px —— 圆角半径的变化不足 1px，
        //  肉眼完全无感。小尺寸元件（状态圆点等）保持精确尺寸：它们尺寸恒定，
        //  本来就不会抖，量化反而会让圆形变成圆角方形。
        // ------------------------------------------------------------------
        const int WidthBucket = 8;      // 宽度量化步长（px）
        const int HeightBucket = 4;     // 高度量化步长（px）
        const int ExactW = 48;          // 窄于此刻度保持精确宽度
        const int ExactH = 24;          // 矮于此高度保持精确高度
        const int ShadowPad = 7;        // 投影向下偏移 2px + 模糊 2.5px 的余量
        const int PillCacheLimit = 192;

        class PillTex
        {
            public int w, h;
            public int radiusQ, bwQ;     // 半径/描边宽 ×100 取整，避免浮点比较
            public Color32 fill, border, shadow;
            public Texture2D tex;
        }

        static readonly List<PillTex> PillCache = new List<PillTex>();

        public static void ClearCache()
        {
            for (int i = 0; i < PillCache.Count; i++)
                if (PillCache[i].tex != null) Object.DestroyImmediate(PillCache[i].tex);
            PillCache.Clear();
            HexCache.Clear();
        }

        static int Quant(float v) { return Mathf.RoundToInt(v * 100f); }

        static bool Eq(Color32 a, Color32 b)
        {
            return a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;
        }

        static int Bucket(int v, int exactBelow, int step)
        {
            if (v < exactBelow) return v;
            return ((v + step - 1) / step) * step;
        }

        static float RoundBoxSdf(float px, float py, float halfW, float halfH, float r)
        {
            r = Mathf.Max(0f, Mathf.Min(r, Mathf.Min(halfW, halfH)));
            float qx = Mathf.Abs(px) - (halfW - r);
            float qy = Mathf.Abs(py) - (halfH - r);
            float mx = Mathf.Max(qx, 0f);
            float my = Mathf.Max(qy, 0f);
            return Mathf.Sqrt(mx * mx + my * my) + Mathf.Min(Mathf.Max(qx, qy), 0f) - r;
        }

        static Color Over(Color src, Color dst)
        {
            float a = src.a + dst.a * (1f - src.a);
            if (a < 0.0005f) return new Color(0f, 0f, 0f, 0f);
            float inv = 1f / a;
            return new Color(
                (src.r * src.a + dst.r * dst.a * (1f - src.a)) * inv,
                (src.g * src.a + dst.g * dst.a * (1f - src.a)) * inv,
                (src.b * src.a + dst.b * dst.a * (1f - src.a)) * inv,
                a);
        }

        static Texture2D BuildPill(int w, int h, float radius, Color fill, Color border, float bw, Color shadow)
        {
            int tw = w + ShadowPad * 2;
            int th = h + ShadowPad * 2;

            bool hasShadow = shadow.a > 0.001f;
            bool hasBorder = bw > 0.001f && border.a > 0.001f;

            var tex = new Texture2D(tw, th, TextureFormat.RGBA32, false, false);
            tex.hideFlags = HideFlags.HideAndDontSave;
            tex.filterMode = FilterMode.Bilinear;
            tex.wrapMode = TextureWrapMode.Clamp;

            var buf = new Color32[tw * th];
            float halfW = w * 0.5f;
            float halfH = h * 0.5f;

            // 投影与描边都关掉时（面板里的小色块、状态圆点）能省掉一半以上的逐像素运算
            for (int y = 0; y < th; y++)
            {
                for (int x = 0; x < tw; x++)
                {
                    float fx = x - ShadowPad + 0.5f - halfW;
                    float fy = y - ShadowPad + 0.5f - halfH;

                    float sd = RoundBoxSdf(fx, fy, halfW, halfH, radius);
                    float outer = Mathf.Clamp01(0.5f - sd);
                    float inner = hasBorder ? Mathf.Clamp01(0.5f - (sd + bw)) : outer;

                    Color c = new Color(0f, 0f, 0f, 0f);

                    if (hasShadow)
                    {
                        // 纹理 v 轴朝上：fy + 2 等价于形状向下偏移 2px
                        float sdShadow = RoundBoxSdf(fx, fy + 2f, halfW, halfH, radius);
                        float shadowA = Mathf.Clamp01(0.5f - (sdShadow - 2.5f)) * shadow.a;
                        c = Over(new Color(shadow.r, shadow.g, shadow.b, shadowA), c);
                    }

                    c = Over(new Color(fill.r, fill.g, fill.b, fill.a * inner), c);

                    if (hasBorder)
                    {
                        float borderA = Mathf.Clamp01(outer - inner);
                        if (borderA > 0.0001f)
                            c = Over(new Color(border.r, border.g, border.b, border.a * borderA), c);
                    }

                    buf[y * tw + x] = c;
                }
            }

            tex.SetPixels32(buf);
            tex.Apply(false, false);
            return tex;
        }

        static Texture2D GetPill(int w, int h, float radius, Color fill, Color border, float bw, Color shadow)
        {
            int rq = Quant(radius), bq = Quant(bw);
            Color32 cFill = fill, cBorder = border, cShadow = shadow;

            for (int i = 0; i < PillCache.Count; i++)
            {
                var p = PillCache[i];
                if (p.w == w && p.h == h && p.radiusQ == rq && p.bwQ == bq
                    && Eq(p.fill, cFill) && Eq(p.border, cBorder) && Eq(p.shadow, cShadow))
                {
                    // 命中就移到队尾，淘汰时从队首取 —— 天然 LRU
                    if (i != PillCache.Count - 1)
                    {
                        PillCache.RemoveAt(i);
                        PillCache.Add(p);
                    }
                    return p.tex;
                }
            }

            while (PillCache.Count >= PillCacheLimit)
            {
                var oldest = PillCache[0];
                if (oldest.tex != null) Object.DestroyImmediate(oldest.tex);
                PillCache.RemoveAt(0);
            }

            var entry = new PillTex
            {
                w = w, h = h, radiusQ = rq, bwQ = bq,
                fill = cFill, border = cBorder, shadow = cShadow,
                tex = BuildPill(w, h, radius, fill, border, bw, shadow)
            };
            PillCache.Add(entry);
            return entry.tex;
        }

        /// <summary>绘制圆角胶囊。颜色变化会触发纹理重建，故只传稳定色值。</summary>
        public static void DrawPill(Rect rect, Color fill, Color border, float radius, float borderWidth, Color shadow)
        {
            if (Event.current != null && Event.current.type != EventType.Repaint) return;

            int w = Mathf.Max(4, Mathf.RoundToInt(rect.width));
            int h = Mathf.Max(4, Mathf.RoundToInt(rect.height));

            // 按分桶后的尺寸取纹理，再拉伸到真实尺寸
            int bw = Bucket(w, ExactW, WidthBucket);
            int bh = Bucket(h, ExactH, HeightBucket);
            var tex = GetPill(bw, bh, radius, fill, border, borderWidth, shadow);

            GUI.DrawTexture(
                new Rect(rect.x - ShadowPad, rect.y - ShadowPad, w + ShadowPad * 2, h + ShadowPad * 2),
                tex, ScaleMode.StretchToFill, true);
        }

        public static void DrawPill(Rect rect, Color fill, Color border, float radius)
        {
            DrawPill(rect, fill, border, radius, PillBorder, ScenePillShadow);
        }

        /// <summary>无投影的实心圆角块（面板内小色条等）。</summary>
        public static void DrawFlatRounded(Rect rect, Color fill, float radius)
        {
            DrawPill(rect, fill, new Color(0f, 0f, 0f, 0f), radius, 0f, new Color(0f, 0f, 0f, 0f));
        }

        // ------------------------------------------------------------------
        //  文本样式
        // ------------------------------------------------------------------
        static GUIStyle _sceneValue;
        static GUIStyle _sceneMeta;

        /// <summary>场景内主数值标签：加粗、居中、富文本。</summary>
        public static GUIStyle SceneValueStyle
        {
            get
            {
                if (_sceneValue == null)
                {
                    _sceneValue = new GUIStyle(EditorStyles.label);
                    _sceneValue.richText = true;
                    _sceneValue.fontSize = (int)LabelFontSize;
                    _sceneValue.fontStyle = FontStyle.Bold;
                    _sceneValue.alignment = TextAnchor.MiddleCenter;
                    _sceneValue.clipping = TextClipping.Clip;
                    _sceneValue.wordWrap = false;
                    _sceneValue.padding = new RectOffset(9, 9, 2, 3);
                }
                _sceneValue.normal.textColor = TextPrimary;
                return _sceneValue;
            }
        }

        /// <summary>场景内次要信息标签：更小、更灰。</summary>
        public static GUIStyle SceneMetaStyle
        {
            get
            {
                if (_sceneMeta == null)
                {
                    _sceneMeta = new GUIStyle(EditorStyles.label);
                    _sceneMeta.richText = true;
                    _sceneMeta.fontSize = (int)MetaFontSize;
                    _sceneMeta.fontStyle = FontStyle.Normal;
                    _sceneMeta.alignment = TextAnchor.MiddleCenter;
                    _sceneMeta.clipping = TextClipping.Clip;
                    _sceneMeta.wordWrap = false;
                    _sceneMeta.padding = new RectOffset(8, 8, 1, 2);
                }
                _sceneMeta.normal.textColor = SceneDimText;
                return _sceneMeta;
            }
        }

        // ------------------------------------------------------------------
        //  颜色 → 富文本字面量
        //
        //  标签内容是带 <color=#RRGGBB> 的富文本，每帧每个标签都要拼一次。
        //  ColorUtility.ToHtmlStringRGB 会分配新字符串，所以这里做缓存 ——
        //  项目里用到的颜色是有限几个，命中率接近 100%。
        // ------------------------------------------------------------------
        static readonly Dictionary<long, string> HexCache = new Dictionary<long, string>();

        static string HexInternal(Color c, bool withAlpha)
        {
            var c32 = (Color32)c;
            long key = ((long)c32.r << 24) | ((long)c32.g << 16) | ((long)c32.b << 8) | c32.a;
            key = (key << 1) | (withAlpha ? 1L : 0L);

            string s;
            if (HexCache.TryGetValue(key, out s)) return s;

            s = withAlpha ? ColorUtility.ToHtmlStringRGBA(c) : ColorUtility.ToHtmlStringRGB(c);
            if (HexCache.Count > 512) HexCache.Clear();
            HexCache[key] = s;
            return s;
        }

        public static string Hex(Color c) { return HexInternal(c, false); }
        public static string HexAlpha(Color c) { return HexInternal(c, true); }
    }
}
