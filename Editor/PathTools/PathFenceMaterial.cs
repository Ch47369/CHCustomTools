using System;
using System.IO;
using UnityEditor;
using UnityEditor.PackageManager;
using UnityEngine;
using UnityEngine.Rendering;

namespace CH.CustomTools.Paths.Editor
{
    internal static class PathFenceMaterial
    {
        internal static string Pipeline()
        {
            var asset = GraphicsSettings.currentRenderPipeline;
            if (asset == null) return "Built-in";
            var type = asset.GetType().Name;
            if (type.Contains("UniversalRenderPipeline")) return "URP";
            if (type.Contains("HDRenderPipeline")) return "HDRP";
            throw new InvalidOperationException("Choose a material for this render pipeline. / 请指定当前渲染管线的材质。");
        }

        internal static Material Create()
        {
            string pipeline = Pipeline();
            string shaderName = "CH/Paths/Custom2TexV2/" + pipeline;
            var shader = Shader.Find(shaderName);
            if (shader == null)
            {
                var package = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(PathFenceMaterial).Assembly);
                string source = Path.Combine(package.resolvedPath, "Samples~", "ElectronicFenceShaders", pipeline, "Custom2TexV2.shader");
                const string folder = "Assets/CHCustomTools/PathShaders";
                string output = folder + "/Custom2TexV2-" + pipeline + ".shader";
                Directory.CreateDirectory(folder);
                if (!File.Exists(output)) File.Copy(source, output);
                AssetDatabase.ImportAsset(output, ImportAssetOptions.ForceSynchronousImport);
                shader = AssetDatabase.LoadAssetAtPath<Shader>(output);
            }
            if (shader == null || shader.name != shaderName || ShaderUtil.ShaderHasError(shader))
                throw new InvalidOperationException("Custom2TexV2 could not compile for " + pipeline + ". / 围栏着色器编译失败，请检查项目管线版本。");
            var material = new Material(shader) { name = "CH Electronic Fence · Custom2TexV2" };
            material.SetColor("_MainTexColor", new Color(.06f, 1.1f, 1.5f, .35f));
            var grid = AssetDatabase.LoadAssetAtPath<Texture2D>("Packages/com.aseshader.handwritten-converter/Runtime/PathTools/FenceGrid.png");
            if (grid != null) material.SetTexture("_MainTex", grid);
            Set(material, "_Src", (int)BlendMode.SrcAlpha);
            Set(material, "_Dst", (int)BlendMode.OneMinusSrcAlpha);
            Set(material, "_ZWriteMode", 0);
            Set(material, "_CullMode", 0);
            if (pipeline == "HDRP")
            {
                // HDRP's default Unlit template owns the actual blend, depth and culling state.
                Set(material, "_SurfaceType", 1);
                Set(material, "_BlendMode", 0);
                Set(material, "_SrcBlend", (int)BlendMode.One);
                Set(material, "_DstBlend", (int)BlendMode.OneMinusSrcAlpha);
                Set(material, "_AlphaSrcBlend", (int)BlendMode.One);
                Set(material, "_AlphaDstBlend", (int)BlendMode.OneMinusSrcAlpha);
                Set(material, "_ZWrite", 0);
                Set(material, "_TransparentZWrite", 0);
                Set(material, "_CullModeForward", 0);
                Set(material, "_DoubleSidedEnable", 1);
                material.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");
                material.EnableKeyword("_DOUBLESIDED_ON");
            }
            return material;
        }

        static void Set(Material material, string property, float value)
        {
            if (material.HasProperty(property)) material.SetFloat(property, value);
        }
    }
}
