using System;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CH.CustomTools.Measurement
{
    [Serializable]
    internal sealed class MeasurementPanel
    {
        [SerializeField] Vector2 scroll;
        [NonSerialized] Action repaint;
        [NonSerialized] bool initialized;
        [NonSerialized] string message;
        static string T(string zh,string en) { return DmText.Pick(zh,en); }
        public void Enable(Action callback) { repaint=callback; EditorApplication.delayCall+=Initialize; }
        void Initialize()
        {
            if(initialized)return;initialized=true;
            DmStore.Reload();DmStore.Changed+=Repaint;DmSceneTool.Changed+=Repaint;
        }
        void Repaint() { if(repaint!=null)repaint(); }
        public void Deactivate() { if(initialized){DmSceneTool.Active=false;DmStore.Flush();} }
        public void Disable()
        {
            EditorApplication.delayCall-=Initialize;Deactivate();
            if(initialized){DmStore.Changed-=Repaint;DmSceneTool.Changed-=Repaint;}initialized=false;repaint=null;
        }
        public void DrawPanel()
        {
            Initialize();DmStore.Reload();
            scroll=EditorGUILayout.BeginScrollView(scroll);
            EditorGUILayout.LabelField(T("距离、角度与面积测量","Distance, angle and area measurement"),EditorStyles.boldLabel);
            EditorGUILayout.LabelField(T("当前活动场景：","Active scene: ")+SceneManager.GetActiveScene().name);
            if(!DmStore.CanEdit)
            {
                DmSceneTool.Active=false;
                EditorGUILayout.HelpBox(T("本场景的本机测量存储无法读取，原数据已保留。请备份并修复对应 EditorPrefs 数据，或切换到其他场景。","Local measurement storage for this scene could not be read. Original data is preserved. Back up and repair its EditorPrefs data, or switch scenes."),MessageType.Error);
                EditorGUILayout.EndScrollView();return;
            }
            EditorGUILayout.HelpBox(T("按 1 个世界单位 = 1 m 显示。角度为两条边的较小夹角（0–180°）；面积仅支持共面、无自交的闭合边界，不是曲面表面积。","Displays 1 world unit as 1 m. Angles are the smaller included angle (0–180°). Area requires a planar, non-intersecting closed boundary; it is not curved surface area."),MessageType.None);
            bool active=EditorGUILayout.ToggleLeft(T("在 Scene 视图中启用测量","Enable measurement in Scene view"),DmSceneTool.Active);
            if(active!=DmSceneTool.Active)DmSceneTool.Active=active;
            if(active) EditorGUILayout.HelpBox(T("左键落点；右键单击 / Enter 完成。回到起点闭合面积。拖动顶点或线段编辑；Shift 正交，Ctrl/⌘ 吸附端点；Backspace 撤回草稿点，Esc 取消或退出。切页或关闭窗口会停止交互。","Left-click to place points; right-click / Enter to finish. Return to the first point to close an area. Drag vertices or segments to edit; Shift constrains axes, Ctrl/⌘ snaps endpoints; Backspace removes a draft point, Esc cancels or exits. Leaving this page or closing the window stops input capture."),MessageType.Info);
            EditorGUILayout.Space();
            EditorGUILayout.LabelField(T("拾取与显示","Picking and display"),EditorStyles.boldLabel);
            DmSceneTool.SnapSurface=EditorGUILayout.Toggle(T("表面吸附","Snap to surface"),DmSceneTool.SnapSurface);
            DmSceneTool.SnapGrid=EditorGUILayout.Toggle(T("网格吸附","Snap to grid"),DmSceneTool.SnapGrid);
            using(new EditorGUI.DisabledScope(!DmSceneTool.SnapGrid))DmSceneTool.GridStepIndex=EditorGUILayout.Popup(T("网格步长","Grid step"),DmSceneTool.GridStepIndex,DmSceneTool.GridStepNames);
            EditorGUILayout.BeginHorizontal();EditorGUILayout.LabelField(T("网格索引","Mesh index"),DmSceneTool.SurfaceInfo);
            if(GUILayout.Button(T("重建","Rebuild"),GUILayout.Width(75)))DmSceneTool.RebuildSurface();EditorGUILayout.EndHorizontal();
            DmSceneTool.Decimals=EditorGUILayout.IntSlider(T("小数位","Decimal places"),DmSceneTool.Decimals,0,4);
            DmSceneTool.XRay=EditorGUILayout.Toggle(T("穿透显示","Draw through geometry"),DmSceneTool.XRay);
            DmSceneTool.ShowEndpoints=EditorGUILayout.Toggle(T("端点标记","Endpoint markers"),DmSceneTool.ShowEndpoints);
            DmSceneTool.ShowDelta=EditorGUILayout.Toggle(T("轴向分量","Axis components"),DmSceneTool.ShowDelta);
            DmSceneTool.ShowAngles=EditorGUILayout.Toggle(T("角度标注","Angle labels"),DmSceneTool.ShowAngles);
            if(DmSceneTool.HasDraft)
            {
                EditorGUILayout.BeginHorizontal(EditorStyles.helpBox);GUILayout.Label(T("草稿点数：","Draft points: ")+DmSceneTool.DraftCount);
                if(GUILayout.Button(T("取消草稿","Cancel draft")))DmSceneTool.CancelDraft();EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.Space();EditorGUILayout.LabelField(T("测量记录","Measurements")+" ("+DmStore.Count+")",EditorStyles.boldLabel);
            MeasureEntry remove=null;
            foreach(var entry in DmStore.Entries.ToArray())
            {
                if(entry==null)continue;
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);EditorGUILayout.BeginHorizontal();
                Color color=EditorGUILayout.ColorField(GUIContent.none,entry.color,false,false,false,GUILayout.Width(40));
                string title=EditorGUILayout.TextField(entry.title??"");
                if(color!=entry.color || title!=entry.title){DmStore.RecordUndo("Edit measurement");entry.color=color;entry.title=title;DmStore.NotifyEdited();}
                string value=entry.kind==MeasureKind.Area?float.IsNaN(entry.Area())?T("无效边界","Invalid boundary"):DmSceneTool.Fmt(entry.Area())+" m²":DmSceneTool.Fmt(entry.TotalLength())+" m";
                GUILayout.Label(value,GUILayout.Width(115));EditorGUILayout.EndHorizontal();
                if(entry.kind==MeasureKind.Area)
                {
                    double area;string reason;
                    if(!DmGeometry.TryArea(entry.points,out area,out reason))EditorGUILayout.HelpBox(reason,MessageType.Warning);
                    else GUILayout.Label(T("周长：","Perimeter: ")+DmSceneTool.Fmt(entry.TotalLength())+" m");
                }
                else if(entry.points!=null && entry.points.Count>2)GUILayout.Label(T("首尾距离：","First-to-last distance: ")+DmSceneTool.Fmt(entry.DirectLength())+" m");
                EditorGUILayout.BeginHorizontal();
                bool visible=GUILayout.Toggle(entry.visible,T("显示","Visible"));
                if(visible!=entry.visible){DmStore.RecordUndo("Show measurement");entry.visible=visible;DmStore.NotifyEdited();}
                if(GUILayout.Button(T("定位","Frame")) && SceneView.lastActiveSceneView!=null)SceneView.lastActiveSceneView.Frame(entry.GetBounds(),false);
                if(GUILayout.Button(T("删除","Delete")))remove=entry;
                EditorGUILayout.EndHorizontal();EditorGUILayout.EndVertical();
            }
            if(remove!=null)DmStore.Remove(remove);
            if(DmStore.Count==0)EditorGUILayout.HelpBox(T("没有测量记录。启用后在 Scene 视图中放置测量点。","No measurements. Enable the tool and place points in Scene view."),MessageType.None);
            if(GUILayout.Button(T("清空当前场景记录（可撤销）","Clear active scene measurements (undoable)")) && DmStore.Count>0)DmStore.Clear();
            EditorGUILayout.Space();
            if(AppDomain.CurrentDomain.GetAssemblies().Any(a=>a.GetType("UnityToolbox.DistanceMeasure.DmSceneTool")!=null))
                EditorGUILayout.HelpBox(T("检测到旧独立测量插件。请先关闭旧插件的测量开关，避免两个工具同时处理场景输入；导入记录并确认后可移除旧包。","The standalone measurement plugin is installed. Disable its measurement mode to avoid two tools handling Scene input. Import and verify records before removing the old package."),MessageType.Warning);
            if(GUILayout.Button(T("导入本场景旧版记录（保留旧数据）","Import legacy records for this scene (preserve originals)")))
            {
                try { int count=DmStore.ImportLegacy();message=T("已导入记录：","Imported records: ")+count; }
                catch(Exception ex){message=ex.Message;}
            }
            if(!string.IsNullOrEmpty(message))EditorGUILayout.HelpBox(message,MessageType.Info);
            EditorGUILayout.HelpBox(T("记录按项目及场景保存在本机 EditorPrefs；不会修改场景或生成运行时物体。首次保存场景会保留记录。撤销适用于当前活动场景；切换场景会结束当前交互并保存。","Records are stored locally in EditorPrefs per project and scene. No scene edits or runtime objects are created. Saving a new scene preserves its records. Undo applies to the active scene; changing scenes finishes interaction and saves records."),MessageType.None);
            EditorGUILayout.EndScrollView();
        }
    }
}
