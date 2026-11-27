using System;
using System.IO;
using UnityEditor;

namespace ASEShaderConverter.Editor
{
    // Compatibility methods for callers of the retired bundled library.
    public static class ShaderLibraryAssets
    {
        internal const string RemovedMessage = "The bundled shader library was removed in CH Custom Tools 0.7.6.";
        public static ShaderLibraryCatalog Load()
        {
            return new ShaderLibraryCatalog { version = "0.7.6", scope = RemovedMessage };
        }
        public static string PackageRoot()
        {
            var package = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(ShaderConverterApi).Assembly);
            if (package != null) return Path.GetFullPath(package.resolvedPath);
            foreach (string guid in AssetDatabase.FindAssets("ShaderLibraryWindow t:MonoScript"))
            {
                string file = AssetDatabase.GUIDToAssetPath(guid);
                if (file.EndsWith("/Editor/ShaderLibraryWindow.cs", StringComparison.Ordinal))
                    return Path.GetFullPath(Path.GetDirectoryName(Path.GetDirectoryName(file)));
            }
            throw new DirectoryNotFoundException("Cannot locate the package root.");
        }
        public static string VerifiedPath(ShaderLibraryEntry entry) { throw new NotSupportedException(RemovedMessage); }
        public static string Import(string id, bool installWaterSupport = true) { throw new NotSupportedException(RemovedMessage); }
    }
}
