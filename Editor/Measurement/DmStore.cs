using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CH.CustomTools.Measurement
{
    [InitializeOnLoad]
    internal static class DmStore
    {
        const string Prefix="CH.CustomTools.Measurement.Scene.";
        const string Legacy="UnityToolbox.DistanceMeasure.Scene.";
        static DmUndoState state;
        static string key="";
        static int sceneHandle;
        static bool dirty, queued, blocked;
        static DmPayload Data { get { if(state==null) Reload(); return state.data; } }
        public static event Action Changed;
        public static event Action ContextChanging;
        public static List<MeasureEntry> Entries { get { return Data.entries; } }
        public static int Count { get { return Entries.Count; } }
        public static bool CanEdit { get { var data=Data; return !blocked; } }
        [Serializable] sealed class StoredPayload { public List<MeasureEntry> entries=null; public int nextIndex=1; }
        static DmPayload ReadPayload(string json)
        {
            var loaded=JsonUtility.FromJson<StoredPayload>(json);
            if(loaded==null || loaded.entries==null || loaded.nextIndex<1)throw new FormatException("Invalid measurement payload");
            foreach(var entry in loaded.entries)
                if(entry==null || entry.points==null || entry.points.Count<2 || entry.points.Exists(p=>!DmGeometry.Finite(p)) ||
                    (entry.kind!=MeasureKind.Length && entry.kind!=MeasureKind.Area))throw new FormatException("Invalid measurement entry");
            return new DmPayload{entries=loaded.entries,nextIndex=loaded.nextIndex};
        }
        static string Project { get { return Hash128.Compute(Path.GetFullPath(Application.dataPath).Replace('\\','/')).ToString(); } }
        static string Key(Scene scene)
        {
            string id=string.IsNullOrEmpty(scene.path)?"Unsaved."+SessionToken+"."+scene.handle:AssetDatabase.AssetPathToGUID(scene.path);
            return Prefix+Project+"."+id;
        }
        static string SessionToken
        {
            get { const string name="CH.Measurement.Session"; var s=SessionState.GetString(name,""); if(s.Length==0){s=Guid.NewGuid().ToString("N");SessionState.SetString(name,s);} return s; }
        }
        static DmStore()
        {
            EditorApplication.delayCall+=Reload;
            EditorSceneManager.activeSceneChangedInEditMode+=(a,b)=>Reload();
            EditorSceneManager.sceneSaved+=SceneSaved;
            AssemblyReloadEvents.beforeAssemblyReload+=Flush;
            EditorApplication.quitting+=Flush;
            Undo.undoRedoPerformed+=OnUndo;
        }
        static void SceneSaved(Scene scene)
        {
            if(scene.handle!=sceneHandle || state==null) return;
            Flush(); string next=Key(scene); if(next==key || blocked) return;
            // First save / Save As keeps the current measurements. The old preference remains recoverable.
            key=next; blocked=false; dirty=true; Flush(); Raise();
        }
        public static void Reload()
        {
            Scene scene=SceneManager.GetActiveScene(); string next=Key(scene);
            if(state!=null && next==key) return;
            if(ContextChanging!=null) ContextChanging(); Flush();
            if(state!=null) { Undo.ClearUndo(state); UnityEngine.Object.DestroyImmediate(state); }
            state=ScriptableObject.CreateInstance<DmUndoState>(); state.hideFlags=HideFlags.HideAndDontSave;
            key=next;sceneHandle=scene.handle;dirty=false;blocked=false;
            string json=EditorPrefs.GetString(key,"");
            if(json.Length>0)
            {
                try { state.data=ReadPayload(json); }
                catch(Exception) { blocked=true; Debug.LogWarning(DmText.Pick("[场景测量] 保存的数据无法读取；原记录已保留，未覆盖。", "[Scene measurement] Saved data could not be read. Original records are preserved without overwrite.")); }
            }
            Raise();
        }
        static void OnUndo() { if(state!=null){dirty=true;QueueSave();Raise();} }
        public static void RecordUndo(string title)
        {
            var current=Data;
            if(blocked) throw new InvalidOperationException(DmText.Pick("测量存储损坏，请先备份或修复对应偏好数据。", "Measurement storage is damaged. Back up or repair its preference data first."));
            Undo.RegisterCompleteObjectUndo(state,title);
        }
        public static void Raise() { if(Changed!=null) Changed(); }
        public static void Flush() { if(!dirty || state==null || blocked) return; EditorPrefs.SetString(key,JsonUtility.ToJson(state.data));dirty=false; }
        static void QueueSave() { if(queued)return;queued=true;EditorApplication.delayCall+=()=>{queued=false;Flush();}; }
        public static void NotifyEdited() { dirty=true;QueueSave();Raise(); }
        public static MeasureEntry Add(List<Vector3> points,Color color,MeasureKind kind=MeasureKind.Length)
        {
            if(points==null || points.Count<2 || points.Exists(p=>!DmGeometry.Finite(p))) throw new ArgumentException("Invalid measurement points");
            if(kind==MeasureKind.Area){double area;string reason;if(!DmGeometry.TryArea(points,out area,out reason))throw new ArgumentException(reason);}
            RecordUndo("Add measurement");
            var entry=new MeasureEntry { id=Guid.NewGuid().ToString("N"),title=DmText.Pick("测量 ","Measurement ")+Data.nextIndex++,points=new List<Vector3>(points),color=color,kind=kind };
            Entries.Add(entry);NotifyEdited();return entry;
        }
        public static void Remove(MeasureEntry entry) { if(!Entries.Contains(entry))return;RecordUndo("Delete measurement");Entries.Remove(entry);NotifyEdited(); }
        public static void Clear() { if(Count==0)return;RecordUndo("Clear measurements");Entries.Clear();Data.nextIndex=1;NotifyEdited(); }
        public static float GrandTotal() { float total=0;foreach(var e in Entries)if(e!=null && e.kind==MeasureKind.Length)total+=e.TotalLength();return total; }
        public static float GrandArea() { float total=0;foreach(var e in Entries)if(e!=null && e.kind==MeasureKind.Area){float a=e.Area();if(!float.IsNaN(a))total+=a;}return total; }
        public static int ImportLegacy()
        {
            Scene scene=SceneManager.GetActiveScene();
            if(string.IsNullOrEmpty(scene.path))throw new InvalidOperationException(DmText.Pick("请先保存场景，再导入旧记录。", "Save the scene before importing legacy records."));
            string json=EditorPrefs.GetString(Legacy+AssetDatabase.AssetPathToGUID(scene.path),"");
            if(json.Length==0)return 0;
            var payload=ReadPayload(json);
            RecordUndo("Import legacy measurements");int count=0;
            foreach(var e in payload.entries){if(!string.IsNullOrEmpty(e.id)&&Entries.Exists(x=>x!=null&&x.id==e.id))continue;Entries.Add(e);count++;}
            Data.nextIndex=Mathf.Max(Data.nextIndex,payload.nextIndex);NotifyEdited();return count;
        }
    }
}
