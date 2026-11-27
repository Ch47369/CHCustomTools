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

        internal static Material Create(PathFenceStyle style = PathFenceStyle.CyanGrid)
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
            string texture;
            Color tint;
            float speed;
            switch (style)
            {
                case PathFenceStyle.AmberWarning:
                    texture = "FenceWarning"; tint = new Color(2.0f, .67f, .06f, .9f); speed = -.42f;
                    break;
                case PathFenceStyle.VioletEnergy:
                    texture = "FenceEnergy"; tint = new Color(.78f, .22f, 2.0f, .9f); speed = .65f;
                    break;
                default:
                    texture = "FenceGridBright"; tint = new Color(.06f, 1.4f, 2.1f, .9f); speed = -.55f;
                    break;
            }
            material.name = "CH Electronic Fence · " + style;
            material.SetColor("_MainTexColor", tint);
            const string assetFolder = "Packages/com.aseshader.handwritten-converter/Runtime/PathTools/";
            var pattern = AssetDatabase.LoadAssetAtPath<Texture2D>(assetFolder + texture + ".png");
            var scan = AssetDatabase.LoadAssetAtPath<Texture2D>(assetFolder + "FenceSweep.png");
            if (pattern != null)
            {
                material.SetTexture("_MainTex", pattern);
                material.SetTextureScale("_MainTex", Vector2.one);
                material.SetTextureOffset("_MainTex", Vector2.zero);
                material.SetVector("_MainTexPanner", Vector4.zero);
            }
            if (scan != null)
            {
                material.SetTexture("_AddTex", scan);
                material.SetTextureScale("_AddTex", Vector2.one);
                material.SetTextureOffset("_AddTex", Vector2.zero);
                material.SetColor("_AddTexColor", new Color(tint.r * .65f, tint.g * .65f, tint.b * .65f, .7f));
                material.SetFloat("_AddTexIntensity", .8f);
                material.SetVector("_AddTexPanner", new Vector4(0, speed, 0, 0));
                material.SetFloat("_TexBlendMode", 2);
            }
            Set(material, "_RA", 1);
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
