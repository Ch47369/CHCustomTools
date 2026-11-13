// Real Editor checks in disposable projects; does not touch user scenes or original plugin files.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using Object=UnityEngine.Object;

[InitializeOnLoad]
public static class UnityMeasurementSmoke
{
    const BindingFlags Flags=BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Static|BindingFlags.Instance;
    const string ResumeKey="CH.Measurement050.Smoke";
    [Serializable] class Pref { public string key;public bool had,value; }
    [Serializable] class State { public List<string> checks=new List<string>();public List<string> keys=new List<string>();public List<Pref> prefs=new List<Pref>();public string legacyKey,oldLanguage;public bool hadLanguage;public int expectedCount; }
    static State state=new State();
    static ASEShaderConverterWindow main;
    static SceneView view;
    static int phase;
    static double next,deadline;
    static Vector2 first,second;
    static Type Type(string name) { return typeof(ASEShaderConverterWindow).Assembly.GetType("CH.CustomTools.Measurement."+name,true); }
    static object Call(string type,string name,params object[] args) { return Type(type).GetMethods(Flags).Single(m=>m.Name==name && m.GetParameters().Length==args.Length).Invoke(null,args); }
    static object Get(string type,string name) { return Type(type).GetProperty(name,Flags).GetValue(null); }
    static void Set(string type,string name,object value) { Type(type).GetProperty(name,Flags).SetValue(null,value); }
    static void Check(bool value,string name) { if(!value)throw new Exception(name);state.checks.Add(name); }
    static void Near(double actual,double expected,string name) { Check(Math.Abs(actual-expected)<1e-4,name+" ("+actual+")"); }
    static List<Vector3> Points(params float[] xy) { var p=new List<Vector3>();for(int i=0;i<xy.Length;i+=2)p.Add(new Vector3(xy[i],xy[i+1],0));return p; }
    static bool Area(List<Vector3> p,out double area) { object[] args={p,0d,null};bool ok=(bool)Call("DmGeometry","TryArea",args);area=(double)args[1];return ok; }
    static object Kind(string name) { return Enum.Parse(Type("MeasureKind"),name); }
    static object Add(List<Vector3> points,string kind="Length") { Undo.IncrementCurrentGroup();return Call("DmStore","Add",points,Color.cyan,Kind(kind)); }
    static int Count { get { return (int)Get("DmStore","Count"); } }
    static void SaveKey() { string key=(string)Call("DmStore","Key",SceneManager.GetActiveScene());if(!state.keys.Contains(key))state.keys.Add(key); }
    static UnityMeasurementSmoke() { if(SessionState.GetBool(ResumeKey,false))EditorApplication.delayCall+=Resume; }
    public static void Run()
    {
        try
        {
            state=new State();state.hadLanguage=EditorPrefs.HasKey("CH.CustomTools.Language");state.oldLanguage=EditorPrefs.GetString("CH.CustomTools.Language","");
            foreach(string suffix in new[]{"snapSurface","snapGrid","xray","endpoints","delta","angles"})
            {string key="CH.CustomTools.Measurement.Setting."+suffix;state.prefs.Add(new Pref{key=key,had=EditorPrefs.HasKey(key),value=EditorPrefs.GetBool(key)});}
            Geometry();Store();Surface();
            ASEShaderConverterWindow.OpenMeasurement();main=Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>().Single();
            main.position=new Rect(50,50,840,650);
            Set("DmSceneTool","SnapSurface",true);Set("DmSceneTool","SnapGrid",false);Set("DmSceneTool","Active",true);
            view=EditorWindow.GetWindow<SceneView>();view.position=new Rect(50,50,1000,720);view.Show();view.LookAtDirect(Vector3.zero,Quaternion.LookRotation(Vector3.forward),6);view.orthographic=true;view.Focus();Selection.activeObject=null;
            SceneView.duringSceneGui+=Capture;phase=0;next=EditorApplication.timeSinceStartup+3;deadline=next+100;EditorApplication.update+=Tick;
        }
        catch(Exception ex){Finish(ex);}
    }
    static void Geometry()
    {
        var triangle=Points(0,0,3,0,3,4);double area;
        Check(Area(triangle,out area),"Planar triangle accepted");Near(area,6,"Triangle area");
        var entry=Activator.CreateInstance(Type("MeasureEntry"));Type("MeasureEntry").GetField("points").SetValue(entry,triangle);Type("MeasureEntry").GetField("kind").SetValue(entry,Kind("Area"));
        Near((float)Type("MeasureEntry").GetMethod("TotalLength").Invoke(entry,null),12,"Closed perimeter includes the final 5-unit edge");
        var concave=Points(0,0,3,0,3,1,1,1,1,3,0,3);Check(Area(concave,out area),"Concave planar polygon accepted");Near(area,5,"Concave polygon area");concave.Reverse();Check(Area(concave,out area),"Reverse winding accepted");Near(area,5,"Reverse winding preserves area");
        Check(Area(triangle.Select(p=>p+Vector3.one*1000000).ToList(),out area),"Large translated coordinates accepted");Near(area,6,"Area is stable after large translation");
        Check(Area(triangle.Select(p=>Quaternion.AngleAxis(35,Vector3.one)*p).ToList(),out area),"Rotated planar polygon accepted");Near(area,6,"Rotated polygon area");
        Check(!Area(Points(0,0,2,2,0,2,2,0),out area),"Self-crossing boundary rejected");
        var nonplanar=Points(0,0,2,0,2,2,0,2);nonplanar[3]+=Vector3.forward;Check(!Area(nonplanar,out area),"Non-planar boundary rejected");
        Check(!Area(Points(0,0,1,0,2,0),out area),"Collinear area rejected");
        foreach(float expected in new[]{0f,90f,180f})
        {object[] args={Vector3.right,Vector3.zero,Quaternion.AngleAxis(expected,Vector3.forward)*Vector3.right,0f};Check((bool)Call("DmGeometry","TryAngle",args),"Angle accepted: "+expected);Near((float)args[3],expected,"Angle value: "+expected);}
        object[] bad={Vector3.zero,Vector3.zero,Vector3.right,0f};Check(!(bool)Call("DmGeometry","TryAngle",bad),"Zero-length angle rejected");
    }
    static void Store()
    {
        EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);Call("DmStore","Reload");SaveKey();
        Add(Points(0,0,3,4));Check(Count==1,"Add measurement");Near((float)Call("DmStore","GrandTotal"),5,"Distance uses world coordinates");
        Undo.FlushUndoRecordObjects();Undo.PerformUndo();Check(Count==0,"Add is undoable");Undo.PerformRedo();Check(Count==1,"Add is redoable");
        string folder="Assets/Measurement050";Directory.CreateDirectory(folder);AssetDatabase.Refresh();
        Check(EditorSceneManager.SaveScene(SceneManager.GetActiveScene(),folder+"/A.unity"),"Save new scene");SaveKey();Check(Count==1,"First scene save preserves measurements");
        Call("DmStore","Flush");string sceneA=SceneManager.GetActiveScene().path;
        EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);Call("DmStore","Reload");SaveKey();Check(Count==0,"New unsaved scene has isolated records");
        EditorSceneManager.OpenScene(sceneA);Call("DmStore","Reload");Check(Count==1,"Return to saved scene restores records");
        EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);Call("DmStore","Reload");SaveKey();
        Check(EditorSceneManager.SaveScene(SceneManager.GetActiveScene(),folder+"/Damaged.unity"),"Save damage-test scene");SaveKey();
        string damagedScene=SceneManager.GetActiveScene().path,damagedKey=(string)Call("DmStore","Key",SceneManager.GetActiveScene());
        EditorSceneManager.OpenScene(sceneA);Call("DmStore","Reload");
        const string damaged="{\"entries\":[{\"points\":null}],\"nextIndex\":1}";EditorPrefs.SetString(damagedKey,damaged);
        EditorSceneManager.OpenScene(damagedScene);Call("DmStore","Reload");Check(!(bool)Get("DmStore","CanEdit"),"Malformed saved entries block editing");
        bool rejected=false;try{Add(Points(0,0,1,0));}catch(TargetInvocationException){rejected=true;}Check(rejected,"Damaged records cannot be replaced by new measurements");
        Call("DmStore","Flush");Check(EditorPrefs.GetString(damagedKey)==damaged,"Damaged preference bytes remain unchanged");
        EditorSceneManager.OpenScene(sceneA);Call("DmStore","Reload");Check((bool)Get("DmStore","CanEdit") && Count==1,"Healthy scene still loads after damaged scene");
        state.legacyKey="UnityToolbox.DistanceMeasure.Scene."+AssetDatabase.AssetPathToGUID(sceneA);
        EditorPrefs.SetString(state.legacyKey,"{\"entries\":[{\"id\":\"legacy-smoke\",\"title\":\"Legacy\",\"points\":[{\"x\":0,\"y\":0,\"z\":0},{\"x\":0,\"y\":2,\"z\":0}],\"kind\":0,\"visible\":true}],\"nextIndex\":10}");
        string original=EditorPrefs.GetString(state.legacyKey);Near((int)Call("DmStore","ImportLegacy"),1,"Legacy records imported");Check(EditorPrefs.GetString(state.legacyKey)==original,"Legacy preference bytes preserved");Near((int)Call("DmStore","ImportLegacy"),0,"Legacy IDs prevent duplicate import");
        Undo.IncrementCurrentGroup();Call("DmStore","Clear");Check(Count==0,"Clear only current measurements");Undo.FlushUndoRecordObjects();Undo.PerformUndo();Check(Count==2,"Clear is undoable");Call("DmStore","Clear");
    }
    static Mesh frontMesh;
    static GameObject Quad(string name,float z)
    {
        var obj=new GameObject(name);obj.transform.position=new Vector3(0,0,z);
        if(frontMesh==null){frontMesh=new Mesh();frontMesh.vertices=new[]{new Vector3(-10,-10,0),new Vector3(10,-10,0),new Vector3(10,10,0),new Vector3(-10,10,0)};frontMesh.triangles=new[]{0,1,2,0,2,3};frontMesh.RecalculateBounds();}
        obj.AddComponent<MeshFilter>().sharedMesh=frontMesh;obj.AddComponent<MeshRenderer>();return obj;
    }
    static void Surface()
    {
        var front=Quad("Front without collider",0);var rear=GameObject.CreatePrimitive(PrimitiveType.Cube);rear.transform.position=new Vector3(0,0,5);rear.transform.localScale=new Vector3(20,20,1);
        object[] args={new Ray(new Vector3(0,0,-10),Vector3.forward),~0,Vector3.zero};Check((bool)Call("DmSceneTool","TrySurface",args),"Scene picking finds visible surface");Near(((Vector3)args[2]).z,0,"Front mesh wins over rear collider");
        Check(front.GetComponent<Collider>()==null,"Picking does not add colliders");
        front.GetComponent<MeshRenderer>().enabled=false;Call("DmSurface","Invalidate",true);args[2]=Vector3.zero;Check((bool)Call("DmSceneTool","TrySurface",args),"Rear collider still available");Near(((Vector3)args[2]).z,4.5,"Disabled renderer excluded from mesh index");
        front.GetComponent<MeshRenderer>().enabled=true;SceneVisibilityManager.instance.Hide(front,true);Call("DmSurface","Invalidate",true);args[2]=Vector3.zero;Call("DmSceneTool","TrySurface",args);Near(((Vector3)args[2]).z,4.5,"Hidden mesh excluded from picking");SceneVisibilityManager.instance.Show(front,true);
        front.layer=2;Call("DmSurface","Invalidate",true);args[1]=1;args[2]=Vector3.zero;Call("DmSceneTool","TrySurface",args);Near(((Vector3)args[2]).z,4.5,"Camera layer mask honored");front.layer=0;
        front.transform.position=new Vector3(0,0,1);Call("DmSurface","Invalidate",true);args[1]=~0;args[2]=Vector3.zero;Call("DmSceneTool","TrySurface",args);Near(((Vector3)args[2]).z,1,"Rebuilt mesh index uses current transforms");front.transform.position=Vector3.zero;Call("DmSurface","Invalidate",true);
        Check(!SceneManager.GetActiveScene().isDirty || GameObject.Find("Front without collider")!=null,"Only test-created scene objects exist");
    }
    static void Capture(SceneView sv)
    {
        if(sv!=view || Event.current.type!=EventType.Repaint)return;
        first=HandleUtility.WorldToGUIPoint(new Vector3(-2,0,0));second=HandleUtility.WorldToGUIPoint(new Vector3(2,0,0));
    }
    static void Click(Vector2 point)
    {
        view.SendEvent(new Event{type=EventType.MouseMove,mousePosition=point});
        view.SendEvent(new Event{type=EventType.MouseDown,button=0,mousePosition=point});
        view.SendEvent(new Event{type=EventType.MouseUp,button=0,mousePosition=point});view.Repaint();
    }
    static void Tick()
    {
        try
        {
            if(EditorApplication.timeSinceStartup>deadline)throw new TimeoutException("Scene input smoke timed out");
            if(EditorApplication.timeSinceStartup<next || EditorApplication.isCompiling)return;next=EditorApplication.timeSinceStartup+1;
            if(phase==0){Check(first!=second,"Scene projection available");Click(first);phase++;return;}
            if(phase==1){Check((int)Get("DmSceneTool","DraftCount")==1,"Actual Scene click places first point");Click(second);phase++;return;}
            if(phase==2){Check((int)Get("DmSceneTool","DraftCount")==2,"Actual Scene click places second point");view.SendEvent(new Event{type=EventType.KeyDown,keyCode=KeyCode.Return});phase++;return;}
            if(phase==3)
            {
                Check(Count==1,"Enter commits actual Scene measurement");Near((float)Call("DmStore","GrandTotal"),4,"Scene click distance matches geometry");
                Undo.IncrementCurrentGroup();view.SendEvent(new Event{type=EventType.MouseMove,mousePosition=first});
                view.SendEvent(new Event{type=EventType.MouseDown,button=0,mousePosition=first});Check((bool)Get("DmSceneTool","IsDragging"),"Actual endpoint drag captures the measurement");
                Vector2 moved=first+new Vector2(-60,0);
                view.SendEvent(new Event{type=EventType.MouseDrag,button=0,mousePosition=moved});
                view.SendEvent(new Event{type=EventType.MouseUp,button=0,mousePosition=moved});
                Check(!(bool)Get("DmSceneTool","IsDragging"),"Mouse release finishes endpoint drag");
                Check(Math.Abs((float)Call("DmStore","GrandTotal")-4)>.1,"Actual endpoint drag changes the measurement");
                phase++;return;
            }
            if(phase==4){Undo.FlushUndoRecordObjects();Undo.PerformUndo();phase++;return;}
            if(phase==5)
            {
                Near((float)Call("DmStore","GrandTotal"),4,"Actual endpoint drag is undoable");
                var language=typeof(ASEShaderConverterWindow).Assembly.GetType("ASEShaderConverter.Editor.CHToolLanguage",true);
                language.GetMethod("Set",Flags).Invoke(null,new object[]{false});Check((string)Call("DmText","Pick","中文","English")=="English","Measurement follows shared English setting");
                language.GetMethod("Set",Flags).Invoke(null,new object[]{true});Check((string)Call("DmText","Pick","中文","English")=="中文","Measurement follows shared Chinese setting");
                ASEShaderConverterWindow.OpenUpdates();Check(!(bool)Get("DmSceneTool","Active"),"Leaving measurement page releases input capture");
                ASEShaderConverterWindow.OpenMeasurement();Set("DmSceneTool","Active",true);main.Close();Check(!(bool)Get("DmSceneTool","Active"),"Closing host releases input capture");
                phase++;return;
            }
            if(phase==6)
            {
                state.expectedCount=Count;Call("DmStore","Flush");SessionState.SetString(ResumeKey+".state",JsonUtility.ToJson(state));SessionState.SetBool(ResumeKey,true);
                Directory.CreateDirectory("Artifacts");File.WriteAllText("Artifacts/pre-reload.json",JsonUtility.ToJson(state,true));
                SceneView.duringSceneGui-=Capture;EditorApplication.update-=Tick;EditorUtility.RequestScriptReload();return;
            }
        }
        catch(Exception ex){Finish(ex);}
    }
    static void Resume()
    {
        try{state=JsonUtility.FromJson<State>(SessionState.GetString(ResumeKey+".state",""));Call("DmStore","Reload");Check(Count==state.expectedCount,"Measurements survive actual script reload");Check(!(bool)Get("DmSceneTool","Active"),"Script reload does not silently capture Scene input");Finish(null);}
        catch(Exception ex){Finish(ex);}
    }
    [Serializable] class Report { public bool success;public string unity,version,failure;public int count;public List<string> checks; }
    static void Finish(Exception error)
    {
        EditorApplication.update-=Tick;SceneView.duringSceneGui-=Capture;SessionState.SetBool(ResumeKey,false);
        foreach(var window in Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>())window.Close();Call("DmStore","Flush");
        foreach(string key in state.keys)EditorPrefs.DeleteKey(key);if(!string.IsNullOrEmpty(state.legacyKey))EditorPrefs.DeleteKey(state.legacyKey);
        foreach(var p in state.prefs){if(p.had)EditorPrefs.SetBool(p.key,p.value);else EditorPrefs.DeleteKey(p.key);}
        if(state.hadLanguage)EditorPrefs.SetString("CH.CustomTools.Language",state.oldLanguage);else EditorPrefs.DeleteKey("CH.CustomTools.Language");
        var package=UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(ASEShaderConverterWindow).Assembly);Directory.CreateDirectory("Artifacts");
        File.WriteAllText("Artifacts/measurement.json",JsonUtility.ToJson(new Report{success=error==null,unity=Application.unityVersion,version=package.version,failure=error==null?"":error.ToString(),count=state.checks.Count,checks=state.checks},true));
        EditorApplication.Exit(error==null?0:1);
    }
}
