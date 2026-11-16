using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using ASEShaderConverter.Editor;
using CH.CustomTools.Paths;
using CH.CustomTools.Paths.Editor;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using Object = UnityEngine.Object;

public static class UnitySceneStabilitySmoke
{
    const BindingFlags F = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static;
    [Serializable] sealed class Frame { public int phase, visible, samples, colored; public string image; }
    [Serializable] sealed class Report { public string version, unity, status, failure; public int count; public string[] passed; public Frame[] frames; }
    static readonly List<string> checks = new List<string>(); static readonly List<Frame> frames = new List<Frame>();
    static Type M(string name) { return typeof(ASEShaderConverterWindow).Assembly.GetType("CH.CustomTools.Measurement." + name, true); }
    static object Call(string type, string name, params object[] args) { return M(type).GetMethod(name,F).Invoke(null,args); }
    static object Get(string type,string name) { return M(type).GetProperty(name,F).GetValue(null); }
    static void Set(string name,object value) { M("DmSceneTool").GetProperty(name,F).SetValue(null,value); }
    static void Check(bool value,string text) { if(!value)throw new Exception(text);checks.Add(text); }
    static SceneView view; static BezierPath path; static RenderTexture captured; static int phase; static double next, deadline;
    static Vector2 a,b,c,start,lastMouse; static Vector3 origin; static Quaternion navigationRotation; static string key, original; static bool hadKey; static string errors;
    static readonly Dictionary<string, bool?> preferences = new Dictionary<string, bool?>();
    static int Count { get { return ((System.Collections.IList)Get("DmStore","Entries")).Count; } }
    static void Add(Vector3[] points, Color color, bool area)
    { Call("DmStore","Add",new List<Vector3>(points),color,Enum.Parse(M("MeasureKind"),area?"Area":"Length")); }
    static bool interactive;
    public static void Preview() { interactive = true; Run(); }
    public static void Run()
    {
        CHValidationInput.Install();
        try
        {
            PlayerSettings.runInBackground=true;
            foreach (string setting in new[] { "angles", "endpoints", "xray", "snapSurface" })
            { string k = "CH.CustomTools.Measurement.Setting."+setting; preferences[k] = EditorPrefs.HasKey(k) ? (bool?)EditorPrefs.GetBool(k) : null; }
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);Call("DmStore","Reload");
            key=(string)Call("DmStore","Key",UnityEngine.SceneManagement.SceneManager.GetActiveScene());hadKey=EditorPrefs.HasKey(key);original=EditorPrefs.GetString(key);
            Call("DmStore","Clear");Set("Active",false);Set("ShowAngles",true);Set("ShowEndpoints",true);Set("XRay",true);Set("SnapSurface",false);
            Add(new[]{new Vector3(-4,0,-2),new Vector3(0,0,-2),new Vector3(-1,0,1)},Color.red,true);
            Add(new[]{new Vector3(1,0,-2),new Vector3(4,0,-2),new Vector3(4,0,1)},Color.yellow,false);
            Add(new[]{new Vector3(-3,0,2),new Vector3(1,0,3)},Color.green,false);
            path=new GameObject("Mixed display path").AddComponent<BezierPath>();path.knots=new List<PathKnot>{new PathKnot(new Vector3(-5,0,4)),new PathKnot(new Vector3(0,0,6)),new PathKnot(new Vector3(5,0,4))};
            Selection.activeObject=path;PathSceneTool.Active=true;
            view=EditorWindow.GetWindow<SceneView>();view.position=new Rect(30,30,1000,780);view.Show();view.showGrid=false;view.drawGizmos=false;
            view.LookAtDirect(Vector3.zero,Quaternion.Euler(55,15,0),8);view.orthographic=false;view.Focus();
            SceneView.duringSceneGui+=Capture;Application.logMessageReceived+=Log;
            next=EditorApplication.timeSinceStartup+2;deadline=next+(interactive?300:90);EditorApplication.update+=Tick;
        }
        catch(Exception e){Finish(e);}
    }
    static void Log(string message,string stack,LogType type) { if(type==LogType.Error||type==LogType.Exception||type==LogType.Assert)errors=message+stack; }
    static Vector2 Screen(Vector3 p) { return GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(p))-view.position.position; }
    static void Capture(SceneView scene)
    {
        if (scene != view) return;
        if(Event.current.type!=EventType.Repaint)return;
        captured=RenderTexture.active;a=Screen(origin+new Vector3(-3,0,-3));b=Screen(origin+new Vector3(0,0,-3));c=Screen(origin+new Vector3(-1,0,0));start=Screen(origin+new Vector3(3,0,3));
    }
    static void Mouse(EventType type,int button,Vector2 p) { CHValidationInput.Send(view, new Event{type=type,button=button,mousePosition=p,delta=type==EventType.MouseDrag?p-lastMouse:Vector2.zero});lastMouse=p;view.Repaint(); }
    static void Click(Vector2 p) { Mouse(EventType.MouseMove,0,p);Mouse(EventType.MouseDown,0,p);Mouse(EventType.MouseUp,0,p); }
    static void Tick()
    {
        try
        {
            if(EditorApplication.timeSinceStartup>deadline)throw new TimeoutException("Scene stability timeout");
            if(EditorApplication.timeSinceStartup<next||captured==null)return;
            if(errors!=null)throw new Exception(errors);next=EditorApplication.timeSinceStartup+.4;
            if(phase<24)
            {
                var old=RenderTexture.active;var tex=new Texture2D(captured.width,captured.height,TextureFormat.RGBA32,false);
                try
                {
                    RenderTexture.active=captured;tex.ReadPixels(new Rect(0,0,tex.width,tex.height),0,0);tex.Apply();
                    int samples=0,visible=0;
                    for(int s=0;s<path.SegmentCount;s++)for(int i=2;i<=18;i++)
                    {
                        Vector3 p,t;path.Cubic(s,i/20f,out p,out t);var v=view.camera.WorldToViewportPoint(p);if(v.z<=view.camera.nearClipPlane)continue;
                        bool hit=false;int x=Mathf.RoundToInt(v.x*tex.width),y=Mathf.RoundToInt(v.y*tex.height);
                        for(int dx=-5;dx<=5&&!hit;dx++)for(int dy=-5;dy<=5;dy++){var color=tex.GetPixel(Mathf.Clamp(x+dx,0,tex.width-1),Mathf.Clamp(y+dy,0,tex.height-1));if(color.g>.35f&&color.b>.35f&&color.r<color.g*.7f){hit=true;break;}}
                        samples++;if(hit)visible++;
                    }
                    Directory.CreateDirectory("Artifacts");string image="mixed-"+phase+".png";File.WriteAllBytes("Artifacts/"+image,tex.EncodeToPNG());
                    frames.Add(new Frame{phase=phase,samples=samples,visible=visible,colored=tex.GetPixels().Count(v=>v.g>.35f&&v.b>.35f&&v.r<v.g*.7f),image=image});
                    Debug.Log("Stability phase "+phase+": "+visible+"/"+samples);
                }
                finally{RenderTexture.active=old;Object.DestroyImmediate(tex);}
                phase++;
                if (phase == 12)
                {
                    origin = new Vector3(100000, 10000, 100000); path.transform.position = origin;
                    foreach (var item in (System.Collections.IList)Get("DmStore","Entries")) { var points = (List<Vector3>)item.GetType().GetField("points").GetValue(item); for (int n = 0; n < points.Count; n++) points[n] += origin; }
                }
                view.LookAtDirect(origin+new Vector3(.0001f*phase,0,0),Quaternion.Euler(55+phase*.05f,15+phase*.05f,0),8);view.orthographic=(phase%12)>=6;captured=null;view.Repaint();return;
            }
            if(phase==24)
            {
                origin=Vector3.zero;path.transform.position=origin;view.LookAtDirect(Vector3.zero,Quaternion.Euler(55,15,0),8);
                Call("DmStore","Clear");Set("Active",true);Selection.activeObject=null;view.Focus();phase++;return;
            }
            if(phase==25)
            {
                Click(a);Click(b);Click(c);Check((int)Get("DmSceneTool","DraftCount")==3,"Three actual left clicks create a draft");
                var pos=view.camera.transform.position;var rot=view.camera.transform.rotation;
                Mouse(EventType.MouseDown,1,a);Mouse(EventType.MouseUp,1,a);
                Check(Count==1&&!(bool)Get("DmSceneTool","HasDraft"),"Right click at start completes one record without forcing closure");
                var entry=((System.Collections.IList)Get("DmStore","Entries"))[0];Check(entry.GetType().GetField("kind").GetValue(entry).ToString()=="Length","Right click keeps three-point measurement open even near its first point");
                Check(view.camera.transform.position==pos&&view.camera.transform.rotation==rot,"Right click completion does not move the Scene camera");
                phase++;return;
            }
            if(phase==26)
            {
                Click(start);Check((int)Get("DmSceneTool","DraftCount")==1&&Count==1,"Next left click begins a separate measurement record");
                Call("DmSceneTool","CancelDraft");
                var ca=a+new Vector2(0,100);var cb=b+new Vector2(0,100);var cc=c+new Vector2(0,100);Click(ca);Click(cb);Click(cc);Click(ca);
                Check(Count==2&&!(bool)Get("DmSceneTool","HasDraft"),"Only left clicking the start closes an area record");
                var closed=((System.Collections.IList)Get("DmStore","Entries"))[1];Check(closed.GetType().GetField("kind").GetValue(closed).ToString()=="Area","Explicit closure still computes an area");
                Click(start);Click(start+new Vector2(50,0));Mouse(EventType.MouseDown,1,start);Mouse(EventType.MouseUp,1,start);
                Check(Count==3&&!(bool)Get("DmSceneTool","HasDraft"),"A two-point distance finishes with one right click");
                view.orthographic=false;Click(start+new Vector2(-100,0));navigationRotation=view.rotation;Mouse(EventType.MouseDown,1,start);Mouse(EventType.MouseDrag,1,start+new Vector2(70,30));
                phase++;return;
            }
            if(phase==27)
            {
                if (interactive && Quaternion.Angle(navigationRotation, view.rotation) < .1f)
                { File.WriteAllText("Artifacts/await-native.txt", "Right-drag in the Scene view to verify native camera navigation. Scene rect: "+view.position); return; }
                Mouse(EventType.MouseDrag,1,start+new Vector2(100,50));Mouse(EventType.MouseUp,1,start+new Vector2(100,50));
                Check(Count==3&&(int)Get("DmSceneTool","DraftCount")==1,"Right drag preserves the draft and does not commit a record");
                Check((bool)Get("DmSceneTool","Active"), "Native navigation leaves measurement enabled");
                Call("DmSceneTool","CancelDraft");Set("Active",false);
                Check(frames.All(f=>f.visible>=f.samples*.9f),"Path remains visible with multiple measurement labels during all camera movements");
                Call("DmStore","Clear");
                path.transform.position=Vector3.zero;path.knots=new List<PathKnot>{new PathKnot(new Vector3(-2,0,-2)),new PathKnot(new Vector3(2,0,2))};
                view.LookAtDirect(Vector3.zero,Quaternion.identity,.1f);view.orthographic=false;Selection.activeObject=path;PathSceneTool.Active=true;
                phase++;captured=null;view.Repaint();return;
            }
            if (phase==28)
            {
                var old=RenderTexture.active;var tex=new Texture2D(captured.width,captured.height,TextureFormat.RGBA32,false);
                try
                {
                    RenderTexture.active=captured;tex.ReadPixels(new Rect(0,0,tex.width,tex.height),0,0);tex.Apply();
                    int colored=tex.GetPixels().Count(v=>v.g>.35f&&v.b>.35f&&v.r<v.g*.7f);
                    Check(colored>100&&colored<tex.width*tex.height*.03f,"Near-plane crossing clips the path stroke without screen-filling spikes");
                    File.WriteAllBytes("Artifacts/near-plane.png",tex.EncodeToPNG());
                }
                finally{RenderTexture.active=old;Object.DestroyImmediate(tex);}
                Finish(null);
            }
        }
        catch(Exception e){Finish(e);}
    }
    static void Finish(Exception failure)
    {
        EditorApplication.update-=Tick;SceneView.duringSceneGui-=Capture;Application.logMessageReceived-=Log;
        try{Set("Active",false);Call("DmStore","Clear");Call("DmStore","Flush");if(key!=null){if(hadKey)EditorPrefs.SetString(key,original);else EditorPrefs.DeleteKey(key);}}catch{}
        foreach (var preference in preferences) { if (preference.Value.HasValue) EditorPrefs.SetBool(preference.Key, preference.Value.Value); else EditorPrefs.DeleteKey(preference.Key); }
        Directory.CreateDirectory("Artifacts");File.WriteAllText("Artifacts/scene-stability.json",JsonUtility.ToJson(new Report{version=UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(BezierPath).Assembly).version,unity=Application.unityVersion,status=failure==null?"Passed":"Failed",failure=failure==null?"":failure.ToString(),count=checks.Count,passed=checks.ToArray(),frames=frames.ToArray()},true));
        EditorApplication.Exit(failure==null?0:1);
    }
}
