// Copied into an isolated project's Assets/Editor by Tools~/Prepare-Validation.ps1.
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using ASEShaderConverter.Editor;
using ASEShaderConverter;

public static class UnitySmoke
{
    public static void Run()
    {
        var env = AseEditorBridge.Probe();
        File.WriteAllText("environment.json", JsonUtility.ToJson(env, true));
        if (env.errors.Count > 0) throw new Exception(string.Join("; ", env.errors.ToArray()));
        var description = AseEditorBridge.DescribeTemplate(AseEditorBridge.BuiltInUnlitGuid, "SamplerNode", "TexturePropertyNode", "SwizzleNode", "DynamicAppendNode");
        File.WriteAllText("template.json", JsonUtility.ToJson(description, true));
        Shader sourceShader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/TintedTexture.shader");
        AssertCompiled(sourceShader);
        var report = ShaderConverterApi.ConvertFile("Assets/TintedTexture.shader", AssetDatabase.GenerateUniqueAssetPath("Assets/TintedTexture_ASE.shader"));
        File.WriteAllText("conversion.json", JsonUtility.ToJson(report, true));
        if (report.status != "Generated" || !report.aseRoundTripPassed || !report.shaderCompiled) throw new Exception(JsonUtility.ToJson(report, true));
        CompareImages(sourceShader, AssetDatabase.LoadAssetAtPath<Shader>(report.outputPath), "texture");
        report.visualComparisonPassed = true;
        report.warnings.Add("Pixel comparison passed for this fixture and the material settings in UnitySmoke only.");
        File.WriteAllText("conversion.json", JsonUtility.ToJson(report, true));

        string text = File.ReadAllText("Assets/TintedTexture.shader");
        string math = text.Replace("return sampled * _Tint * _Strength;", "return float4(exp2(i.uv.x), log2(_Tint.y + 1), rcp(_Strength + 1), 1);");
        var mathAnalysis = ShaderConversionEngine.Analyze(math);
        mathAnalysis.plan.shaderName += "_Math";
        var mathReport = AseEditorBridge.Generate(mathAnalysis.plan, AssetDatabase.GenerateUniqueAssetPath("Assets/NativeMath_ASE.shader"), mathAnalysis.report);
        File.WriteAllText("native-math.json", JsonUtility.ToJson(mathReport, true));
        if (mathReport.status != "Generated" || mathReport.customExpressionCount != 0) throw new Exception(JsonUtility.ToJson(mathReport, true));
        CompareSource(math.Replace("ConverterSamples/TintedTexture\"", "ConverterSamples/MathSource\""), mathReport, "math");
        File.WriteAllText("native-math.json", JsonUtility.ToJson(mathReport, true));

        var customAnalysis = ShaderConversionEngine.Analyze(text);
        customAnalysis.plan.shaderName += "_CustomLoop";
        var node = customAnalysis.plan.nodes.Last(n => n.type == "SimpleMultiplyOpNode");
        node.type = "CustomExpressionNode"; node.outputType = "FLOAT4";
        node.fallbackReason = "The input-dependent loop needs code; ASE's standard math nodes do not represent a loop with a variable iteration count.";
        node.code = "float4 result = seed; int count = (int)clamp(steps,0.0,8.0); for (int k=0;k<count;k++) { result=sin(result+0.1); } return result;";
        node.customInputs.Add(new CustomInput { name = "seed", type = "FLOAT4" });
        node.customInputs.Add(new CustomInput { name = "steps", type = "FLOAT" });
        var customReport = AseEditorBridge.Generate(customAnalysis.plan, AssetDatabase.GenerateUniqueAssetPath("Assets/CustomLoop_ASE.shader"));
        File.WriteAllText("custom-loop.json", JsonUtility.ToJson(customReport, true));
        if (customReport.status != "Generated" || customReport.customExpressionCount != 1) throw new Exception(JsonUtility.ToJson(customReport, true));
        string customSource = text.Replace("return sampled * _Tint * _Strength;", node.code.Replace("seed", "(sampled * _Tint)").Replace("steps", "_Strength"));
        CompareSource(customSource.Replace("ConverterSamples/TintedTexture\"", "ConverterSamples/LoopSource\""), customReport, "loop");
        File.WriteAllText("custom-loop.json", JsonUtility.ToJson(customReport, true));
        Debug.Log("ASE_CONVERTER_SMOKE_PASS");
        EditorApplication.Exit(0);
    }

    private static void AssertCompiled(Shader shader)
    {
        if (shader == null) throw new Exception("Source Shader was not imported.");
        var material = new Material(shader);
        try { for (int pass = 0; pass < material.passCount; pass++) ShaderUtil.CompilePass(material, pass, true); }
        finally { UnityEngine.Object.DestroyImmediate(material); }
        if (ShaderUtil.ShaderHasError(shader)) throw new Exception("Source Shader failed to compile: " + string.Join("; ", ShaderUtil.GetShaderMessages(shader).Select(m => m.message).ToArray()));
    }

    private static void CompareSource(string text, ShaderConversionReport report, string fixture)
    {
        string path = "Assets/" + fixture + "_Source.shader";
        File.WriteAllText(path, text);
        AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceSynchronousImport | ImportAssetOptions.ForceUpdate);
        Shader source = AssetDatabase.LoadAssetAtPath<Shader>(path);
        AssertCompiled(source);
        CompareImages(source, AssetDatabase.LoadAssetAtPath<Shader>(report.outputPath), fixture);
        report.visualComparisonPassed = true;
        report.warnings.Add("Pixel comparison passed for this fixture and the material settings in UnitySmoke only.");
    }

    public static void CompareImages(Shader original, Shader converted, string fixture)
    {
        AssertCompiled(original);
        AssertCompiled(converted);
        var texture = new Texture2D(2, 2, TextureFormat.RGBA32, false, true) { filterMode = FilterMode.Point };
        texture.SetPixels(new[] { new Color(0.1f,0.3f,0.5f,0.2f), new Color(0.8f,0.2f,0.1f,0.7f), new Color(0.2f,0.7f,0.4f,0.4f), new Color(0.9f,0.6f,0.2f,0.9f) });
        texture.Apply();
        Texture2D left = null, right = null;
        try
        {
            left = Render(original, texture); right = Render(converted, texture);
            File.WriteAllBytes(fixture + "-source.png", left.EncodeToPNG()); File.WriteAllBytes(fixture + "-generated.png", right.EncodeToPNG());
            Color[] a = left.GetPixels(), b = right.GetPixels();
            float error = 0;
            for (int i = 0; i < a.Length; i++) for (int c = 0; c < 4; c++) error = Mathf.Max(error, Mathf.Abs(a[i][c] - b[i][c]));
            File.WriteAllText(fixture + "-pixel-comparison.txt", "32x32 RGBA, max absolute error: " + error.ToString("R", System.Globalization.CultureInfo.InvariantCulture));
            if (error > 2f / 255f) throw new Exception("Rendered shader output differs: " + error);
        }
        finally { UnityEngine.Object.DestroyImmediate(texture); if(left != null) UnityEngine.Object.DestroyImmediate(left); if(right != null) UnityEngine.Object.DestroyImmediate(right); }
    }

    private static Texture2D Render(Shader shader, Texture input)
    {
        var material = new Material(shader);
        if (material.HasProperty("_Tint")) material.SetColor("_Tint", new Color(0.7f, 0.45f, 0.2f, 0.6f));
        if (material.HasProperty("_Strength")) material.SetFloat("_Strength", 1.3f);
        var target = RenderTexture.GetTemporary(32, 32, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        RenderTexture previous = RenderTexture.active;
        bool srgb = GL.sRGBWrite;
        try
        {
            int pass = material.FindPass("Unlit");
            if (pass < 0) pass = 0;
            File.AppendAllText("render-passes.txt", shader.name + ": " + pass + "/" + material.passCount + " " + material.GetPassName(pass) + Environment.NewLine);
            GL.sRGBWrite = false; Graphics.Blit(input, target, material, pass);
            RenderTexture.active = target;
            var pixels = new Texture2D(32, 32, TextureFormat.RGBA32, false, true);
            pixels.ReadPixels(new Rect(0, 0, 32, 32), 0, 0); pixels.Apply(); return pixels;
        }
        finally { GL.sRGBWrite = srgb; RenderTexture.active = previous; RenderTexture.ReleaseTemporary(target); UnityEngine.Object.DestroyImmediate(material); }
    }
}
