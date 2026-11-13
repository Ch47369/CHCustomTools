// Run only in an isolated project; exercises real imported Shader assets and Unity drag payloads.
using System;
using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEngine;
using ASEShaderConverter;
using ASEShaderConverter.Editor;

public static class UnityWindowSmoke
{
    private static int checks;
    private static readonly Type WindowType = typeof(ASEShaderConverterWindow);
    private static readonly BindingFlags PrivateInstance = BindingFlags.NonPublic | BindingFlags.Instance;
    private static void Check(bool passed, string name) { if (!passed) throw new Exception(name); checks++; }
    private static object Call(object window, string name, params object[] args) { return WindowType.GetMethod(name, PrivateInstance).Invoke(window, args); }
    private static object Get(object window, string name) { return WindowType.GetField(name, PrivateInstance).GetValue(window); }

    public static void Run()
    {
        ASEShaderConverterWindow window = null;
        try
        {
            var environment = AseEditorBridge.Probe();
            File.WriteAllText("window-environment.json", JsonUtility.ToJson(environment, true));
            Check(environment.errors.Count == 0, "The isolated Unity/ASE environment must be ready");
            var shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/TintedTexture.shader");
            Check(shader != null, "Source Shader must be imported");
            window = ScriptableObject.CreateInstance<ASEShaderConverterWindow>();
            Call(window, "SetInput", Path.GetFullPath("Assets/TintedTexture.shader"));
            Check((string)Get(window, "inputPath") == "Assets/TintedTexture.shader", "Normalize absolute Project input paths");
            Check((Shader)Get(window, "inputShader") == shader, "Populate the Shader object slot");
            string output = (string)Get(window, "outputPath");
            Check(output.StartsWith("Assets/") && output != "Assets/TintedTexture.shader" && !File.Exists(output), "Output must be new and inside Assets");
            Call(window, "Analyze");
            var analysis = (ShaderConversionAnalysis)Get(window, "analysis");
            Check(analysis.report.CanGenerate && !(bool)Get(window, "generationAttempted"), "Analysis must not claim generation or validation");

            DragAndDrop.PrepareStartDrag();
            DragAndDrop.objectReferences = new UnityEngine.Object[] { shader };
            CheckDragged(true, "Assets/TintedTexture.shader", "Project Shader drag");
            DragAndDrop.objectReferences = new UnityEngine.Object[] { shader, shader };
            CheckDragged(false, null, "Reject multi-selection without replacing input");
            DragAndDrop.objectReferences = new UnityEngine.Object[] { window };
            CheckDragged(false, null, "Reject non-Shader object drags");
            DragAndDrop.objectReferences = new UnityEngine.Object[0];
            DragAndDrop.paths = new[] { Path.GetFullPath("window-external.SHADER") };
            File.WriteAllText(DragAndDrop.paths[0], File.ReadAllText("Assets/TintedTexture.shader"));
            CheckDragged(true, DragAndDrop.paths[0], "External file drag with uppercase extension");
            Call(window, "SetInput", DragAndDrop.paths[0]);
            Check(Get(window, "analysis") == null && !(bool)Get(window, "generationAttempted"), "Changing input must clear old analysis and validation");
            Check(((string)Get(window, "outputPath")).StartsWith("Assets/"), "External input output must stay inside Assets");
            DragAndDrop.paths = new[] { Path.GetFullPath("missing.shader") };
            CheckDragged(false, null, "Reject missing files");
            DragAndDrop.paths = new[] { Path.GetFullPath("window-environment.json") };
            CheckDragged(false, null, "Reject non-Shader files");
            DragAndDrop.paths = new[] { Path.GetFullPath("Assets/TintedTexture.shader"), Path.GetFullPath("window-external.SHADER") };
            CheckDragged(false, null, "Reject multiple external files");

            string packageInput = "Packages/com.aseshader.handwritten-converter/Samples~/Handwritten/TintedTexture.shader";
            Call(window, "SetInput", packageInput);
            Call(window, "Analyze");
            analysis = (ShaderConversionAnalysis)Get(window, "analysis");
            Check(analysis != null && analysis.report.CanGenerate, "Resolve Package Manager virtual paths before reading source");
            Check(((string)Get(window, "outputPath")).StartsWith("Assets/"), "Package input must never output into Packages");

            var messages = WindowType.Assembly.GetType("ASEShaderConverter.Editor.ShaderConverterMessages", true);
            var report = new ShaderConversionReport { status = "NeedsAgent" };
            string original = "Texture kind requires an agent sampler plan: 2DArray";
            report.blockers.Add(original);
            Check((MessageType)messages.GetMethod("Severity").Invoke(null, new object[] { report }) == MessageType.Warning && !report.CanGenerate, "Unsupported semantics stay blocked and display as adaptation warnings");
            string translated = (string)messages.GetMethod("Explain").Invoke(null, new object[] { original });
            Check(translated.Contains("2DArray") && report.blockers[0] == original, "Translation must keep evidence and original diagnostics intact");
            report.status = "ValidationFailed";
            Check((MessageType)messages.GetMethod("Severity").Invoke(null, new object[] { report }) == MessageType.Error, "Actual validation failure remains an error");
            UnityEngine.Object.DestroyImmediate(window);
            window = null;
            File.WriteAllText("window-smoke-result.txt", "PASS: " + checks + " window checks; Unity " + Application.unityVersion);
            Debug.Log("ASE_CONVERTER_WINDOW_SMOKE_PASS: " + checks);
            EditorApplication.Exit(0);
        }
        catch (Exception e)
        {
            File.WriteAllText("window-smoke-error.txt", e.ToString());
            Debug.LogException(e);
            if (window != null) UnityEngine.Object.DestroyImmediate(window);
            EditorApplication.Exit(1);
        }
    }

    private static void CheckDragged(bool expected, string path, string name)
    {
        var method = WindowType.GetMethod("TryGetDraggedShader", BindingFlags.NonPublic | BindingFlags.Static);
        object[] args = { null };
        bool accepted = (bool)method.Invoke(null, args);
        Check(accepted == expected && (!accepted || (string)args[0] == path), name);
    }
}
