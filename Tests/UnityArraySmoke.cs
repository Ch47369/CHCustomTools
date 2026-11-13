// Copy to Assets/Editor in the isolated DeepZoom validation project only.
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using ASEShaderConverter;
using ASEShaderConverter.Editor;

public static class UnityArraySmoke
{
    private static int checks;
    private static void Check(bool ok, string message) { if (!ok) throw new Exception(message); checks++; }
    private static void Save(string path, object value) { File.WriteAllText(path, JsonUtility.ToJson(value, true)); }

    public static void Run()
    {
        try
        {
            if (File.Exists("array-smoke-error.txt")) File.Delete("array-smoke-error.txt");
            if (File.Exists("array-smoke-result.txt")) File.Delete("array-smoke-result.txt");
            File.WriteAllText("array-pixels.txt", "");
            var probe = ShaderConverterApi.Execute(new ShaderAgentRequest { operation = "probe" });
            Save("array-environment.json", probe);
            Check(probe.success, "Unity/ASE must be ready");
            var analysis = ShaderConverterApi.Execute(new ShaderAgentRequest { operation = "analyze", sourcePath = "Assets/Source/DeepZoomPageTable360.shader" });
            Save("array-analysis.json", analysis);
            Check(analysis.success, "Analysis: " + string.Join("; ", analysis.report.blockers.ToArray()));
            Check(analysis.analysis.plan.nodes.All(n => n.type != "CustomExpressionNode"), "All expressions must use native nodes");
            analysis.analysis.plan.shaderName += "_Organized";
            Directory.CreateDirectory("Assets/Generated");
            var result = ShaderConverterApi.Execute(new ShaderAgentRequest { operation = "generatePlan", plan = analysis.analysis.plan, outputPath = AssetDatabase.GenerateUniqueAssetPath("Assets/Generated/DeepZoomPageTable360_ASE.shader") });
            Save("array-conversion.json", result);
            Check(result.success && result.report.aseRoundTripPassed && result.report.shaderCompiled, "Generation: " + result.error + " " + string.Join("; ", result.report.blockers.ToArray()));
            var shader = AssetDatabase.LoadAssetAtPath<Shader>(result.report.outputPath);
            Check(shader.GetPropertyCount() == 6, "Retain the six source properties");
            int array = shader.FindPropertyIndex("_TileArray");
            Check(array >= 0 && shader.GetPropertyTextureDimension(array) == TextureDimension.Tex2DArray, "Texture array dimension");
            foreach (string name in new[] { "_PageTableTransform", "_PageTableLayer", "_FallbackTex" })
                Check((shader.GetPropertyFlags(shader.FindPropertyIndex(name)) & ShaderPropertyFlags.NoScaleOffset) != 0, "Retain NoScaleOffset: " + name);
            Check(shader.GetPropertyAttributes(shader.FindPropertyIndex("_FlipHorizontally")).Contains("Toggle"), "Retain Toggle attribute");
            var material = new Material(shader);
            Check(material.renderQueue == 2000 && material.GetTag("RenderType", false) == "Opaque", "Opaque Geometry queue");
            Check(material.passCount == 1 && material.FindPass("Unlit") >= 0, "Exactly the intended Unlit pass");
            UnityEngine.Object.DestroyImmediate(material);
            var defaultSource = new Material(AssetDatabase.LoadAssetAtPath<Shader>("Assets/Source/DeepZoomPageTable360.shader"));
            var defaultGenerated = new Material(shader);
            Check(defaultSource.GetTexture("_TileArray") == null && defaultGenerated.GetTexture("_TileArray") == null, "Neither default token assigns a texture array asset");
            UnityEngine.Object.DestroyImmediate(defaultSource); UnityEngine.Object.DestroyImmediate(defaultGenerated);
            Compare(AssetDatabase.LoadAssetAtPath<Shader>("Assets/Source/DeepZoomPageTable360.shader"), shader);
            string packageRoot = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(ShaderConverterApi).Assembly).resolvedPath;
            var sample = ShaderConverterApi.Execute(new ShaderAgentRequest { operation = "generate", sourcePath = Path.Combine(packageRoot, "Samples~/Handwritten/ArrayLookup.shader"), outputPath = AssetDatabase.GenerateUniqueAssetPath("Assets/Generated/ArrayLookup_ASE.shader") });
            Save("array-sample.json", sample);
            Check(sample.success && sample.report.aseRoundTripPassed && sample.report.shaderCompiled, "Independent array regression sample must generate and reload");
            // Keep the API report's scene comparison false. Fixture evidence is recorded separately.
            File.WriteAllText("array-smoke-result.txt", "PASS: " + checks + " checks; six synthetic image cases and culling; source/generated images in this project; original user scene not compared.");
            Debug.Log("ASE_ARRAY_SMOKE_PASS: " + checks);
            EditorApplication.Exit(0);
        }
        catch (Exception e)
        {
            File.WriteAllText("array-smoke-error.txt", e.ToString());
            Debug.LogException(e);
            EditorApplication.Exit(1);
        }
    }

    private static void Compare(Shader source, Shader generated)
    {
        var layers = new Texture2DArray(256, 256, 3, TextureFormat.RGBA32, true, true) { filterMode = FilterMode.Point, wrapMode = TextureWrapMode.Clamp };
        var fallback = new Texture2D(256, 256, TextureFormat.RGBA32, true, true) { filterMode = FilterMode.Point, wrapMode = TextureWrapMode.Clamp };
        for (int mip = 0; mip < layers.mipmapCount; mip++)
        {
            int size = Math.Max(1, 256 >> mip);
            for (int layer = 0; layer < 3; layer++)
            {
                var pixels = new Color[size * size];
                for (int y = 0; y < size; y++) for (int x = 0; x < size; x++)
                    pixels[y * size + x] = mip == 0 ? new Color((x + 1f) / 257, (y + 1f) / 257, 0.15f + layer * 0.3f, 0.25f + layer * 0.25f) : Color.magenta;
                layers.SetPixels(pixels, layer, mip);
            }
            var f = new Color[size * size];
            for (int y = 0; y < size; y++) for (int x = 0; x < size; x++) f[y * size + x] = mip == 0 ? new Color(0.85f, x / 300f, y / 350f, 0.35f) : Color.cyan;
            fallback.SetPixels(f, mip);
        }
        layers.Apply(false); fallback.Apply(false);
        var left = new Material(source); var right = new Material(generated);
        try
        {
            for (int grid = 0; grid < 2; grid++)
            {
                int w = grid == 0 ? 4 : 3, h = grid == 0 ? 2 : 3;
                var transform = new Texture2D(w, h, TextureFormat.RGBAFloat, true, true) { filterMode = FilterMode.Point, wrapMode = TextureWrapMode.Clamp };
                var info = new Texture2D(w, h, TextureFormat.RGBAFloat, true, true) { filterMode = FilterMode.Point, wrapMode = TextureWrapMode.Clamp };
                var transforms = new Color[w * h]; var indices = new Color[w * h];
                float[] rounded = { 0.49f, 0.51f, 1.49f, 1.51f };
                float[] valid = { 0f, 0.49f, 0.5f, 1f };
                for (int i = 0; i < transforms.Length; i++)
                {
                    transforms[i] = new Color(0.7f + i * 0.03f, 1.1f, -0.15f + i * 0.04f, -0.05f);
                    indices[i] = new Color(rounded[i % 4], valid[i % 4], 0, 0);
                }
                transform.SetPixels(transforms); info.SetPixels(indices);
                for (int mip = 1; mip < transform.mipmapCount; mip++)
                {
                    int count = Math.Max(1, w >> mip) * Math.Max(1, h >> mip);
                    transform.SetPixels(Enumerable.Repeat(new Color(0, 0, 0, 0), count).ToArray(), mip);
                    info.SetPixels(Enumerable.Repeat(new Color(2, 1, 0, 0), count).ToArray(), mip);
                }
                transform.Apply(false); info.Apply(false);
                try
                {
                    foreach (Material m in new[] { left, right })
                    {
                        m.SetTexture("_TileArray", layers); m.SetTexture("_FallbackTex", fallback);
                        m.SetTexture("_PageTableTransform", transform); m.SetTexture("_PageTableLayer", info);
                        m.SetVector("_PageTableGrid", new Vector4(w, h, 1f / w, 1f / h));
                        foreach (string name in new[] { "_TileArray", "_PageTableTransform", "_PageTableLayer", "_FallbackTex" })
                        { m.SetTextureScale(name, new Vector2(0.27f, 0.39f)); m.SetTextureOffset(name, new Vector2(0.41f, 0.13f)); }
                    }
                    foreach (float flip in new[] { 0f, 0.5f, 1f })
                    {
                        left.SetFloat("_FlipHorizontally", flip); right.SetFloat("_FlipHorizontally", flip);
                        string key = "array-" + w + "x" + h + "-flip" + flip.ToString(System.Globalization.CultureInfo.InvariantCulture);
                        Color[] a = Render(left, false, key + "-source.png"), b = Render(right, false, key + "-generated.png");
                        Check(a.Count(c => c.a > 0.01f) > a.Length * 0.9f, "Reference must render visible backfaces");
                        Check(a.Select(c => (Color32)c).Distinct().Count() > 100, "Reference must contain varied lookup/texture data");
                        float error = 0;
                        for (int i = 0; i < a.Length; i++) for (int c = 0; c < 4; c++) error = Mathf.Max(error, Mathf.Abs(a[i][c] - b[i][c]));
                        File.AppendAllText("array-pixels.txt", key + ": 128x64 RGBA max error=" + error.ToString("R", System.Globalization.CultureInfo.InvariantCulture) + Environment.NewLine);
                        Check(error <= 2f / 255, "Pixel comparison failed: " + key + " " + error);
                    }
                    Color[] culledA = Render(left, true, null), culledB = Render(right, true, null);
                    Check(culledA.All(c => c.a == 0) && culledB.All(c => c.a == 0), "Front faces must be culled in both shaders");
                }
                finally { UnityEngine.Object.DestroyImmediate(transform); UnityEngine.Object.DestroyImmediate(info); }
            }
        }
        finally
        {
            UnityEngine.Object.DestroyImmediate(left); UnityEngine.Object.DestroyImmediate(right);
            UnityEngine.Object.DestroyImmediate(layers); UnityEngine.Object.DestroyImmediate(fallback);
        }
    }

    private static Color[] Render(Material material, bool reverse, string image)
    {
        var mesh = new Mesh();
        mesh.vertices = new[] { new Vector3(-2,-1,0), new Vector3(2,-1,0), new Vector3(2,1,0), new Vector3(-2,1,0) };
        mesh.uv = new[] { new Vector2(-0.2f,-0.1f), new Vector2(1.2f,-0.1f), new Vector2(1.2f,1.1f), new Vector2(-0.2f,1.1f) };
        mesh.triangles = reverse ? new[] { 0,2,1,0,3,2 } : new[] { 0,1,2,0,2,3 };
        mesh.RecalculateBounds();
        var quad = new GameObject("Comparison quad") { layer = 30 };
        quad.AddComponent<MeshFilter>().sharedMesh = mesh;
        quad.AddComponent<MeshRenderer>().sharedMaterial = material;
        var cameraObject = new GameObject("Comparison camera");
        var camera = cameraObject.AddComponent<Camera>();
        camera.transform.position = new Vector3(0,0,-2);
        camera.orthographic = true; camera.orthographicSize = 1; camera.aspect = 2;
        camera.clearFlags = CameraClearFlags.SolidColor; camera.backgroundColor = Color.clear;
        camera.cullingMask = 1 << 30; camera.allowHDR = false; camera.allowMSAA = false;
        var target = RenderTexture.GetTemporary(128,64,24,RenderTextureFormat.ARGB32,RenderTextureReadWrite.Linear);
        var previous = RenderTexture.active;
        Texture2D pixels = null;
        try
        {
            camera.targetTexture = target; camera.Render(); RenderTexture.active = target;
            pixels = new Texture2D(128,64,TextureFormat.RGBA32,false,true);
            pixels.ReadPixels(new Rect(0,0,128,64),0,0); pixels.Apply();
            if (image != null) File.WriteAllBytes(image,pixels.EncodeToPNG());
            return pixels.GetPixels();
        }
        finally
        {
            RenderTexture.active = previous; camera.targetTexture = null; RenderTexture.ReleaseTemporary(target);
            UnityEngine.Object.DestroyImmediate(cameraObject); UnityEngine.Object.DestroyImmediate(quad);
            UnityEngine.Object.DestroyImmediate(mesh); if (pixels != null) UnityEngine.Object.DestroyImmediate(pixels);
        }
    }
}
