using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using UnityEditor;
using UnityEditor.PackageManager;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    public static class ShaderLibraryAssets
    {
        public static ShaderLibraryCatalog Load()
        {
            var asset=Resources.Load<TextAsset>("ASEShaderLibraryCatalog");
            if(asset==null)throw new FileNotFoundException("ASE shader library catalog is missing. Reinstall the complete package.");
            return JsonUtility.FromJson<ShaderLibraryCatalog>(asset.text);
        }
        public static string PackageRoot()
        {
            var package=UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(ShaderConverterApi).Assembly);
            if(package!=null)return Path.GetFullPath(package.resolvedPath);
            foreach(string guid in AssetDatabase.FindAssets("ShaderLibraryWindow t:MonoScript"))
            {
                string file=AssetDatabase.GUIDToAssetPath(guid);
                if(file.EndsWith("/Editor/ShaderLibraryWindow.cs",StringComparison.Ordinal))return Path.GetFullPath(Path.GetDirectoryName(Path.GetDirectoryName(file)));
            }
            throw new DirectoryNotFoundException("Cannot locate the shader library package root.");
        }
        public static string VerifiedPath(ShaderLibraryEntry entry)
        {
            if(entry==null||string.IsNullOrEmpty(entry.path)||Path.IsPathRooted(entry.path)||!entry.path.Replace('\\','/').StartsWith("Samples~/ShaderLibrary/",StringComparison.Ordinal))throw new ArgumentException("Invalid library artifact path.");
            string root=PackageRoot(), path=Path.GetFullPath(Path.Combine(root,entry.path));
            string libraryRoot=Path.GetFullPath(Path.Combine(root,"Samples~/ShaderLibrary"));
            if(!path.StartsWith(libraryRoot.TrimEnd(Path.DirectorySeparatorChar)+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)||!path.EndsWith(".shader",StringComparison.OrdinalIgnoreCase))throw new ArgumentException("Library path must remain inside its shader sample folder.");
            using(var hash=SHA256.Create())
            using(var stream=File.OpenRead(path))
                if(BitConverter.ToString(hash.ComputeHash(stream)).Replace("-","").ToLowerInvariant()!=entry.sha256)throw new InvalidDataException("Library shader checksum mismatch: "+entry.id);
            return path;
        }
        public static string Import(string id, bool installWaterSupport=true)
        {
            var entry=Load().entries.Single(e=>e.id==id);var env=AseEditorBridge.Probe();
            if(env.errors.Count>0)throw new InvalidOperationException(string.Join("\n",env.errors.ToArray()));
            if(env.activePipeline!=entry.pipeline)throw new InvalidOperationException("This shader requires "+entry.pipeline+"; active project uses "+env.activePipeline+".");
            if(!entry.aseRoundTripPassed||!entry.shaderCompiled)throw new InvalidOperationException("This entry has not passed graph reload and shader compilation.");
            string source=VerifiedPath(entry);
            if(id=="original-BuiltIn-DeepWater"&&installWaterSupport)return ImportDeepWater(source);
            string folder="Assets/ASEShaderLibrary/"+entry.category+"/"+entry.pipeline;
            Directory.CreateDirectory(folder);AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            string candidate=folder+"/"+Path.GetFileName(source);
            if(File.Exists(candidate)&&File.ReadAllBytes(candidate).SequenceEqual(File.ReadAllBytes(source)))return candidate;
            foreach(string existing in Directory.EnumerateFiles(folder,Path.GetFileNameWithoutExtension(source)+"*.shader"))
                if(File.ReadAllBytes(existing).SequenceEqual(File.ReadAllBytes(source)))return existing.Replace('\\','/');
            string destination=AssetDatabase.GenerateUniqueAssetPath(candidate);
            File.Copy(source,destination,false);AssetDatabase.ImportAsset(destination,ImportAssetOptions.ForceSynchronousImport);
            Selection.activeObject=AssetDatabase.LoadAssetAtPath<Shader>(destination);EditorGUIUtility.PingObject(Selection.activeObject);
            return destination;
        }
        static string ImportDeepWater(string source)
        {
            const string shader="Assets/Shaders/DeepWater_ASE.shader";
            string root=PackageRoot();
            string[] support={"Runtime/DepthWaterSurface.cs","Editor/DepthWaterAuthoring.cs"};
            if(File.Exists(shader))throw new IOException("DeepWater shader already exists at "+shader+". Existing files are preserved; use the Water tools for the installed sample.");
            foreach(string file in support)
            {
                string target="Assets/Shaders/DeepWater/"+file;
                if(!File.Exists(Path.Combine(root,"Samples~/Water/"+file)))throw new FileNotFoundException("Water support source missing: "+file);
                if(File.Exists(target))throw new IOException("Water support file already exists: "+target);
            }
            // Water authoring creates fresh original textures, mesh, materials and prefab
            // through Unity APIs after script compilation. No copied asset GUIDs are needed.
            Directory.CreateDirectory("Assets/Shaders/DeepWater/Runtime");Directory.CreateDirectory("Assets/Shaders/DeepWater/Editor");
            foreach(string file in support)File.Copy(Path.Combine(root,"Samples~/Water/"+file),"Assets/Shaders/DeepWater/"+file,false);
            File.Copy(source,shader,false);AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            return shader;
        }
    }
}
