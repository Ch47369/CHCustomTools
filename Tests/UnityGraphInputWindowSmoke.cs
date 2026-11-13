using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;

// Sends drag events to the real path control in a task-owned non-batch Editor.
public static class UnityGraphInputWindowSmoke
{
    static ASEShaderConverterWindow window;
    static readonly List<string> checks=new List<string>();
    static int stage;
    static double deadline, timeout;
    static string folder, failure;
    static object Field(string name) { return typeof(ASEShaderConverterWindow).GetField(name,BindingFlags.NonPublic|BindingFlags.Instance).GetValue(window); }
    static void Check(bool ok,string message) { if(!ok)throw new Exception(message);checks.Add(message); }
    static void Log(string message,string stack,LogType type) { if(type==LogType.Exception || type==LogType.Error)failure=message+"\n"+stack; }
    public static void Run()
    {
        try
        {
            folder="Assets/GraphInput046/"+DateTime.UtcNow.ToString("yyyyMMddHHmmssfff"); Directory.CreateDirectory(folder);AssetDatabase.Refresh();
            Check(EditorApplication.ExecuteMenuItem("Tools/Shader"),"Tools/Shader opens converter directly");
            window=EditorWindow.GetWindow<ASEShaderConverterWindow>();window.position=new Rect(100,100,900,800);window.Show();
            typeof(ASEShaderConverterWindow).GetField("acceptStandardUnlitHost",BindingFlags.NonPublic|BindingFlags.Instance).SetValue(window,false);
            EditorJsonUtility.FromJsonOverwrite("{\"acceptStandardTarget\":true}",window);
            Check(!(bool)Field("acceptStandardUnlitHost"),"Old URP-only window consent does not enable the new host option");
            timeout=EditorApplication.timeSinceStartup+35;deadline=EditorApplication.timeSinceStartup+2;
            Application.logMessageReceived+=Log;EditorApplication.update+=Update;
        }
        catch(Exception e){Finish(e.ToString());}
    }
    static void Drop(string path,UnityEngine.Object obj)
    {
        DragAndDrop.PrepareStartDrag();DragAndDrop.objectReferences=obj==null ? new UnityEngine.Object[0] : new[]{obj};DragAndDrop.paths=new[]{path};
        Rect area=(Rect)Field("inputPathArea");Check(area.width>100 && area.height>5,"File path control has a real GUI rectangle");
        window.SendEvent(new Event{type=EventType.DragUpdated,mousePosition=area.center});
        window.SendEvent(new Event{type=EventType.DragPerform,mousePosition=area.center});
    }
    static void Update()
    {
        try
        {
            if(!string.IsNullOrEmpty(failure))throw new Exception(failure);
            if(EditorApplication.timeSinceStartup>timeout)throw new TimeoutException("Window drag test timed out");
            if(EditorApplication.timeSinceStartup<deadline)return;
            if(stage==0)
            {
                Drop(folder,AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(folder));
                Check((string)Field("inputPath")==folder,"Dragging a Unity Project folder onto File path selects it; selected="+Field("inputPath"));
            }
            else if(stage==1)
            {
                Drop(Application.dataPath,null);
                Check((string)Field("inputPath")=="Assets","Dragging a system Assets folder onto File path selects the root; selected="+Field("inputPath"));
                Check(Field("analysis")==null && Directory.GetFiles(folder).Length==0,"Directory drop performs no analysis or file writes");
            }
            else { Finish(null);return; }
            stage++;window.Repaint();deadline=EditorApplication.timeSinceStartup+1;
        }
        catch(Exception e){Finish(e.ToString());}
    }
    static void Finish(string error)
    {
        EditorApplication.update-=Update;Application.logMessageReceived-=Log;DragAndDrop.PrepareStartDrag();
        Directory.CreateDirectory("Artifacts");
        File.WriteAllText("Artifacts/graph-input-window.json",JsonUtility.ToJson(new Result{success=error==null,unityVersion=Application.unityVersion,checks=checks.ToArray(),error=error??""},true));
        if(window!=null)window.Close();EditorApplication.Exit(error==null?0:1);
    }
    [Serializable]sealed class Result{public bool success;public string unityVersion,error;public string[] checks;}
}
