using System;
using System.Collections.Generic;

namespace ASEShaderConverter.Editor
{
    // Old API callers receive an explicit result without scheduling installation work.
    public static class ShaderLibraryBatch
    {
        [Serializable] public sealed class Item
        {
            public string id, shaderPath, materialPath, error;
            public bool success, materialReused;
        }
        [Serializable] public sealed class Report
        {
            public string pipeline;
            public bool completed, cancelled;
            public int requested;
            public List<Item> items = new List<Item>();
        }
        public static bool IsRunning => false;
        public static string LastReport => ShaderLibraryAssets.RemovedMessage;
        public static Report LastResult => null;
        public static string Progress => "";
        public static Item Generate(string id) { return new Item { id = id, error = ShaderLibraryAssets.RemovedMessage }; }
        public static void Start(string[] requested) { throw new NotSupportedException(ShaderLibraryAssets.RemovedMessage); }
        public static void Cancel() { }
    }
}
