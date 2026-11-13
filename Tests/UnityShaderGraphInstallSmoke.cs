// New isolated host with URP and the released tarball, deliberately without ASE.
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public static class UnityShaderGraphInstallSmoke
{
    [Serializable] public class Installed
    {
        public string packageRoot,version,displayName,unityVersion;
        public bool aseInstalled;
    }
    public static void Run()
    {
        try {
            var package=UnityEditor.PackageManager.PackageInfo.GetAllRegisteredPackages().Single(p=>p.name=="com.aseshader.handwritten-converter");
            var installed=new Installed{packageRoot=package.resolvedPath,version=package.version,unityVersion=Application.unityVersion,displayName=package.displayName,
                aseInstalled=AppDomain.CurrentDomain.GetAssemblies().Any(a=>a.GetType("AmplifyShaderEditor.VersionInfo",false)!=null)};
            string evidence=Path.GetFullPath("../../.build~/GraphInterop040/Install"); Directory.CreateDirectory(evidence); File.WriteAllText(evidence+"/installed.json",JsonUtility.ToJson(installed,true));
            if(installed.aseInstalled || installed.version!="0.4.0" || installed.displayName!="Shader转换器" || package.resolvedPath.Replace('\\','/').Equals("F:/ASEShader",StringComparison.OrdinalIgnoreCase)) throw new Exception("Expected released 0.4.0 tarball in a project without ASE.");
            var type=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType("UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset",false)).First(t=>t!=null);
            string path="Assets/InstallPipeline.asset";
            var asset=AssetDatabase.LoadAssetAtPath<RenderPipelineAsset>(path);
            if(asset==null) {
                asset=(RenderPipelineAsset)type.GetMethod("Create").Invoke(null,new object[]{null}); AssetDatabase.CreateAsset(asset,path);
                var serialized=new SerializedObject(asset); var renderer=serialized.FindProperty("m_RendererDataList").GetArrayElementAtIndex(0).objectReferenceValue;
                AssetDatabase.AddObjectToAsset(renderer,asset); AssetDatabase.SaveAssets();
            }
            GraphicsSettings.renderPipelineAsset=asset; QualitySettings.renderPipeline=asset;
            Shader.globalRenderPipeline="UniversalPipeline";
            UnityShaderGraphNativeSmoke.Run();
        } catch(Exception e) { Debug.LogException(e); EditorApplication.Exit(1); }
    }
}
