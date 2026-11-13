using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;

namespace CH.CustomTools.VFX
{
    public enum VfxResourceKind { Texture, Material, Model, Animation, Controller, Prefab, Audio, Shader, Other }

    [Serializable]
    public sealed class VfxResourceRule
    {
        public VfxResourceKind kind;
        public bool enabled = true;
        public string folder;
        public string prefix;
        public string pattern = "{prefix}_{effect}_{index:000}";
        public bool customNaming;
    }

    public static class VfxResourceNaming
    {
        public static readonly string[] Choices =
        {
            "前缀 + 特效名 + 序号（推荐）",
            "前缀 + 原文件名",
            "前缀 + 特效名 + 原文件名",
            "特效名 + 序号",
            "保留原文件名（只移动目录）",
            "自定义（高级）"
        };

        private static readonly string[] Patterns =
        {
            "{prefix}_{effect}_{index:000}", "{prefix}_{name}",
            "{prefix}_{effect}_{name}", "{effect}_{index:000}", "{name}"
        };

        public static int GetChoice(VfxResourceRule rule)
        {
            int index = Array.IndexOf(Patterns, rule.pattern);
            return rule.customNaming || index < 0 ? Patterns.Length : index;
        }

        public static void SetChoice(VfxResourceRule rule, int choice)
        {
            if (choice < 0 || choice >= Choices.Length) throw new ArgumentOutOfRangeException(nameof(choice));
            rule.customNaming = choice == Patterns.Length;
            if (!rule.customNaming) rule.pattern = Patterns[choice];
        }
    }

    [Serializable]
    public sealed class VfxOrganizerSettings
    {
        public string destination = "Assets/VFX/Organized";
        public string effectName = "Effect";
        public bool includeRoots;
        public bool includeShared;
        public List<VfxResourceRule> rules = new List<VfxResourceRule>
        {
            new VfxResourceRule { kind = VfxResourceKind.Texture, folder = "Textures", prefix = "T" },
            new VfxResourceRule { kind = VfxResourceKind.Material, folder = "Materials", prefix = "M" },
            new VfxResourceRule { kind = VfxResourceKind.Model, folder = "Models", prefix = "SM" },
            new VfxResourceRule { kind = VfxResourceKind.Animation, folder = "Animations", prefix = "A" },
            new VfxResourceRule { kind = VfxResourceKind.Controller, folder = "Controllers", prefix = "AC" },
            new VfxResourceRule { kind = VfxResourceKind.Prefab, folder = "Prefabs", prefix = "Prafabs" },
            new VfxResourceRule { kind = VfxResourceKind.Audio, folder = "Audio", prefix = "S" },
            new VfxResourceRule { kind = VfxResourceKind.Shader, folder = "Shaders", prefix = "SH", enabled = false },
            new VfxResourceRule { kind = VfxResourceKind.Other, folder = "Other", prefix = "Data", enabled = false }
        };
    }

    [Serializable]
    internal sealed class VfxOrganizerPreset
    {
        public string format;
        public int version;
        public VfxOrganizerPresetSettings settings;
    }

    // A scheme must contain its own rules. Unity may construct missing nested
    // objects during JSON import, so this transport type has no default rules.
    [Serializable]
    internal sealed class VfxOrganizerPresetSettings
    {
        public string destination, effectName;
        public bool includeRoots, includeShared;
        public List<VfxResourceRule> rules;
    }

    public static class VfxOrganizerPresets
    {
        public static string Serialize(VfxOrganizerSettings settings)
        {
            Validate(settings);
            return JsonUtility.ToJson(new VfxOrganizerPreset
            {
                format = "VfxResourceOrganizer.Settings", version = 1,
                settings = new VfxOrganizerPresetSettings
                {
                    destination = settings.destination, effectName = settings.effectName,
                    includeRoots = settings.includeRoots, includeShared = settings.includeShared, rules = settings.rules
                }
            }, true);
        }

        public static VfxOrganizerSettings Deserialize(string json)
        {
            var preset = new VfxOrganizerPreset();
            JsonUtility.FromJsonOverwrite(json, preset);
            if (preset == null || preset.format != "VfxResourceOrganizer.Settings" || preset.version != 1)
                throw new InvalidOperationException(CHToolLanguage.Text("这不是兼容的资源整理方案，请选择通过“保存整理方案”生成的 JSON 文件。"));
            if (preset.settings == null) throw new InvalidOperationException(CHToolLanguage.Text("整理方案缺少设置，当前设置已保留。"));
            var settings = new VfxOrganizerSettings
            {
                destination = preset.settings.destination, effectName = preset.settings.effectName,
                includeRoots = preset.settings.includeRoots, includeShared = preset.settings.includeShared, rules = preset.settings.rules
            };
            Validate(settings);
            return settings;
        }

        private static void Validate(VfxOrganizerSettings settings)
        {
            if (settings == null || settings.rules == null || settings.rules.Count != Enum.GetValues(typeof(VfxResourceKind)).Length ||
                settings.rules.Any(x => x == null || !Enum.IsDefined(typeof(VfxResourceKind), x.kind) || x.folder == null || x.pattern == null) ||
                settings.rules.Select(x => x.kind).Distinct().Count() != settings.rules.Count)
                throw new InvalidOperationException(CHToolLanguage.Text("整理方案缺少资源类型或存在重复 / 无效配置，当前设置已保留。"));
        }
    }

    public sealed class VfxResourceEntry
    {
        public string path, guid, hash, protection;
        public VfxResourceKind kind;
        public bool isRoot;
        public readonly List<string> externalUsers = new List<string>();
    }

    public sealed class VfxResourceScan
    {
        public GameObject[] roots;
        public readonly List<VfxResourceEntry> entries = new List<VfxResourceEntry>();
        internal string signature;
    }

    public sealed class VfxResourceMove
    {
        public VfxResourceEntry resource;
        public string destination;
    }

    public sealed class VfxResourcePlan
    {
        public VfxResourceScan scan;
        public readonly List<VfxResourceMove> moves = new List<VfxResourceMove>();
    }

    [Serializable]
    public sealed class VfxOrganizerJournalEntry
    {
        public string guid, original, destination;
    }

    [Serializable]
    public sealed class VfxOrganizerJournal
    {
        public string project, time, state;
        public List<VfxOrganizerJournalEntry> entries = new List<VfxOrganizerJournalEntry>();
    }

    /// <summary>Dependency inspection is read-only; every asset mutation uses AssetDatabase.</summary>
    public static class VfxResourceOrganizer
    {
        public static readonly string[] KindNames = { "贴图", "材质", "模型 / 网格", "动画", "动画控制器", "预制体", "音频", "Shader", "其他资源" };
        private static readonly StringComparer Paths = StringComparer.OrdinalIgnoreCase;
        public static string JournalFolder { get { return Path.Combine(Path.GetDirectoryName(Application.dataPath), "Artifacts", "VfxResourceOrganizer"); } }

        public static VfxResourceScan Scan(IEnumerable<GameObject> targets, Func<float, bool> cancel = null)
        {
            var roots = targets.Where(x => x != null).Distinct().ToArray();
            if (roots.Length == 0) throw new InvalidOperationException(CHToolLanguage.Text("请先添加特效预制体或场景物体。"));
            var seeds = new HashSet<string>(Paths);
            var rootPaths = new HashSet<string>(Paths);
            var selectedObjects = new HashSet<Object>();
            var selectedScenes = new HashSet<string>(Paths);
            foreach (var root in roots)
            {
                string path = AssetDatabase.GetAssetPath(root);
                if (EditorUtility.IsPersistent(root))
                {
                    if (!path.EndsWith(".prefab", StringComparison.OrdinalIgnoreCase))
                        throw new InvalidOperationException(CHToolLanguage.Text("Project 中的扫描入口必须是 .prefab；模型请通过场景物体引用。"));
                    seeds.Add(path); rootPaths.Add(path);
                }
                else
                {
                    if (!root.scene.IsValid()) throw new InvalidOperationException(CHToolLanguage.Text("扫描物体已失效。"));
                    if (!string.IsNullOrEmpty(root.scene.path)) selectedScenes.Add(root.scene.path);
                    foreach (Transform transform in root.GetComponentsInChildren<Transform>(true))
                    {
                        selectedObjects.Add(transform.gameObject);
                        foreach (Component component in transform.GetComponents<Component>())
                        {
                            if (component == null) continue;
                            selectedObjects.Add(component);
                            using (var serialized = new SerializedObject(component))
                            {
                                var iterator = serialized.GetIterator();
                                while (iterator.Next(true))
                                {
                                    if (iterator.propertyType != SerializedPropertyType.ObjectReference || iterator.objectReferenceValue == null ||
                                        !EditorUtility.IsPersistent(iterator.objectReferenceValue)) continue;
                                    string referencedPath = AssetDatabase.GetAssetPath(iterator.objectReferenceValue);
                                    if (!string.IsNullOrEmpty(referencedPath)) seeds.Add(referencedPath);
                                }
                            }
                        }
                        var source = PrefabUtility.GetCorrespondingObjectFromSource(transform.gameObject);
                        if (source != null)
                        {
                            string sourcePath = AssetDatabase.GetAssetPath(source);
                            seeds.Add(sourcePath);
                            rootPaths.Add(sourcePath);
                        }
                    }
                }
            }
            var closure = new HashSet<string>(seeds, Paths);
            foreach (string seed in seeds)
                foreach (string dependency in AssetDatabase.GetDependencies(seed, true)) closure.Add(dependency);
            var scan = new VfxResourceScan { roots = roots };
            foreach (string path in closure.OrderBy(x => x, StringComparer.Ordinal))
            {
                if (AssetDatabase.IsValidFolder(path)) continue;
                scan.entries.Add(new VfxResourceEntry
                {
                    path = path, guid = AssetDatabase.AssetPathToGUID(path), kind = Classify(path),
                    hash = AssetDatabase.GetAssetDependencyHash(path).ToString(),
                    protection = Protection(path), isRoot = rootPaths.Contains(path)
                });
            }
            var byPath = scan.entries.ToDictionary(x => x.path, Paths);
            var edges = new Dictionary<string, string[]>(Paths);
            foreach (string path in byPath.Keys) edges[path] = AssetDatabase.GetDependencies(path, false);
            // An outside reference to a material also shares its textures and shader.
            Action<string, string> markShared = (path, owner) =>
            {
                var queue = new Queue<string>();
                var visited = new HashSet<string>(Paths);
                queue.Enqueue(path);
                while (queue.Count > 0)
                {
                    string next = queue.Dequeue();
                    VfxResourceEntry entry;
                    if (!visited.Add(next) || !byPath.TryGetValue(next, out entry)) continue;
                    if (!entry.externalUsers.Contains(owner)) entry.externalUsers.Add(owner);
                    foreach (string dependency in edges[next]) queue.Enqueue(dependency);
                }
            };
            string[] allAssets = AssetDatabase.GetAllAssetPaths();
            for (int i = 0; i < allAssets.Length; i++)
            {
                if (cancel != null && i % 32 == 0 && cancel((float)i / Math.Max(1, allAssets.Length)))
                    throw new OperationCanceledException();
                string owner = allAssets[i];
                if ((!owner.StartsWith("Assets/", StringComparison.Ordinal) && !owner.StartsWith("Packages/", StringComparison.Ordinal)) ||
                    closure.Contains(owner) || selectedScenes.Contains(owner) || AssetDatabase.IsValidFolder(owner)) continue;
                foreach (string dependency in AssetDatabase.GetDependencies(owner, false))
                    if (byPath.ContainsKey(dependency)) markShared(dependency, owner);
            }
            // Saved scene files cannot distinguish individual instances. Inspect the loaded
            // objects outside the selection as well, including unsaved and inactive objects.
            for (int i = 0; i < SceneManager.sceneCount; i++)
            {
                Scene scene = SceneManager.GetSceneAt(i);
                if (!scene.isLoaded || EditorSceneManager.IsPreviewScene(scene)) continue;
                foreach (GameObject sceneRoot in scene.GetRootGameObjects())
                    foreach (Transform transform in sceneRoot.GetComponentsInChildren<Transform>(true))
                    {
                        if (selectedObjects.Contains(transform.gameObject)) continue;
                        string owner = "场景: " + (string.IsNullOrEmpty(scene.path) ? scene.name : scene.path) + "/" + transform.name;
                        var source = PrefabUtility.GetCorrespondingObjectFromSource(transform.gameObject);
                        if (source != null) markShared(AssetDatabase.GetAssetPath(source), owner);
                        foreach (Component component in transform.GetComponents<Component>())
                        {
                            if (component == null) continue;
                            using (var serialized = new SerializedObject(component))
                            {
                                var iterator = serialized.GetIterator();
                                while (iterator.Next(true))
                                    if (iterator.propertyType == SerializedPropertyType.ObjectReference && iterator.objectReferenceValue != null)
                                        markShared(AssetDatabase.GetAssetPath(iterator.objectReferenceValue), owner);
                            }
                        }
                    }
            }
            scan.signature = string.Join("\n", scan.entries.Select(x => x.guid + "|" + x.path + "|" + x.hash + "|" +
                string.Join(";", x.externalUsers.OrderBy(y => y, StringComparer.Ordinal))));
            return scan;
        }

        public static VfxResourcePlan BuildPlan(VfxResourceScan scan, VfxOrganizerSettings settings, ISet<string> excluded = null)
        {
            if (scan == null) throw new InvalidOperationException(CHToolLanguage.Text("请先扫描引用。"));
            var plan = new VfxResourcePlan { scan = scan };
            var counts = new Dictionary<VfxResourceKind, int>();
            var destinations = new HashSet<string>(Paths);
            foreach (var entry in scan.entries)
            {
                var rule = settings.rules.SingleOrDefault(x => x.kind == entry.kind);
                if (!string.IsNullOrEmpty(entry.protection) || rule == null || !rule.enabled ||
                    (entry.isRoot && !settings.includeRoots) || (entry.externalUsers.Count > 0 && !settings.includeShared) ||
                    (excluded != null && excluded.Contains(entry.guid))) continue;
                string folder = ResolveDestinationFolder(settings, rule);
                if ((rule.pattern ?? "").Contains("{effect}")) ValidateName(settings.effectName, CHToolLanguage.Text("特效名"));
                int index; counts.TryGetValue(entry.kind, out index); counts[entry.kind] = ++index;
                string fileName = ExpandName(rule.pattern, rule.prefix, settings.effectName, Path.GetFileNameWithoutExtension(entry.path), index);
                string destination = folder + "/" + fileName + Path.GetExtension(entry.path);
                if (!destinations.Add(destination)) throw new InvalidOperationException(CHToolLanguage.Text("命名方式生成了重复路径，请选择带“序号”或“原文件名”的方式，或修改前缀：") + destination);
                if (!string.Equals(entry.path, destination, StringComparison.Ordinal))
                    plan.moves.Add(new VfxResourceMove { resource = entry, destination = destination });
            }
            ValidateMoves(plan.moves);
            return plan;
        }

        public static string ResolveDestinationFolder(VfxOrganizerSettings settings, VfxResourceRule rule)
        {
            string folder = (rule.folder ?? "").Replace('\\', '/').TrimEnd('/');
            if (folder != "Assets" && !folder.StartsWith("Assets/", StringComparison.Ordinal))
            {
                ValidateRelativeFolder(folder);
                folder = (settings.destination ?? "").Replace('\\', '/').TrimEnd('/') + (folder.Length == 0 ? "" : "/" + folder);
            }
            ValidateAssetFolder(folder);
            return folder;
        }

        public static string ToAssetFolderPath(string absoluteFolder)
        {
            string selected = Path.GetFullPath(absoluteFolder).Replace('\\', '/').TrimEnd('/');
            string assets = Path.GetFullPath(Application.dataPath).Replace('\\', '/').TrimEnd('/');
            string folder;
            if (Paths.Equals(selected, assets)) folder = "Assets";
            else if (selected.StartsWith(assets + "/", StringComparison.OrdinalIgnoreCase)) folder = "Assets" + selected.Substring(assets.Length);
            else throw new InvalidOperationException(CHToolLanguage.Text("目标目录必须位于当前工程的 Assets 内。"));
            ValidateAssetFolder(folder);
            return folder;
        }

        public static string ExpandName(string pattern, string prefix, string effect, string original, int index)
        {
            string result = (pattern ?? "").Replace("{prefix}", prefix ?? "").Replace("{effect}", effect ?? "").Replace("{name}", original ?? "");
            result = Regex.Replace(result, @"\{index(?::(0{1,8}))?\}", match => index.ToString(match.Groups[1].Success ? match.Groups[1].Value : "0", System.Globalization.CultureInfo.InvariantCulture));
            if (result.Contains("{") || result.Contains("}")) throw new InvalidOperationException(CHToolLanguage.Text("命名规则存在未知占位符。支持 {prefix}、{effect}、{name}、{index:000}。"));
            ValidateName(result, CHToolLanguage.Text("生成的文件名"));
            return result;
        }

        public static string Execute(VfxResourcePlan plan, Func<float, bool> cancel = null)
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode) throw new InvalidOperationException(CHToolLanguage.Text("请在非播放模式整理资源。"));
            if (plan == null || plan.moves.Count == 0) throw new InvalidOperationException(CHToolLanguage.Text("没有需要移动的资源。"));
            if (Scan(plan.scan.roots, cancel).signature != plan.scan.signature) throw new InvalidOperationException(CHToolLanguage.Text("引用或资源已变化，请重新扫描并预览。"));
            ValidateMoves(plan.moves);
            var journal = new VfxOrganizerJournal
            {
                project = Path.GetFullPath(Application.dataPath), time = DateTime.Now.ToString("O"), state = "Pending",
                entries = plan.moves.Select(x => new VfxOrganizerJournalEntry { guid = x.resource.guid, original = x.resource.path, destination = x.destination }).ToList()
            };
            Directory.CreateDirectory(JournalFolder);
            string file = Path.Combine(JournalFolder, DateTime.Now.ToString("yyyyMMdd-HHmmss") + "-" + Guid.NewGuid().ToString("N") + ".json");
            SaveJournal(file, journal);
            var temporaryFolders = new List<string>();
            try
            {
                Apply(journal.entries, false, temporaryFolders);
                journal.state = "Completed";
                SaveJournal(file, journal);
                return file;
            }
            catch (Exception error)
            {
                try { Apply(journal.entries, true, temporaryFolders); journal.state = "RolledBack"; }
                catch (Exception rollback) { journal.state = "RecoveryRequired"; throw new InvalidOperationException(CHToolLanguage.Text("整理失败，部分路径需恢复。记录：") + file + "\n" + error.Message + "\n" + rollback.Message, rollback); }
                finally { SaveJournal(file, journal); }
                throw new InvalidOperationException(CHToolLanguage.Text("整理失败，已恢复原路径。") + error.Message, error);
            }
            finally { foreach (string folder in temporaryFolders) DeleteEmptyFolder(folder); }
        }

        public static VfxOrganizerJournal LoadJournal(string file)
        {
            var journal = JsonUtility.FromJson<VfxOrganizerJournal>(File.ReadAllText(file));
            if (journal == null || !Paths.Equals(journal.project, Path.GetFullPath(Application.dataPath)) || journal.entries == null || journal.entries.Count == 0)
                throw new InvalidOperationException(CHToolLanguage.Text("这份整理记录不属于当前工程或内容无效。"));
            return journal;
        }

        public static void Restore(string file)
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode) throw new InvalidOperationException(CHToolLanguage.Text("请在非播放模式恢复资源。"));
            var journal = LoadJournal(file);
            var moves = new List<VfxResourceMove>();
            var guids = new HashSet<string>();
            foreach (var entry in journal.entries)
            {
                ValidateAssetFolder(Path.GetDirectoryName(entry.original).Replace('\\', '/'));
                ValidateName(Path.GetFileNameWithoutExtension(entry.original), CHToolLanguage.Text("原始文件名"));
                string current = AssetDatabase.GUIDToAssetPath(entry.guid);
                if (!guids.Add(entry.guid) || string.IsNullOrEmpty(current)) throw new InvalidOperationException(CHToolLanguage.Text("资源已删除或记录含重复 GUID：") + entry.guid);
                if (current == entry.original) continue;
                moves.Add(new VfxResourceMove { resource = new VfxResourceEntry { guid = entry.guid, path = current }, destination = entry.original });
            }
            ValidateMoves(moves);
            // Restore uses the same transactional path, so a failed restore also rolls back.
            var reverse = new VfxOrganizerJournal { project = journal.project, time = DateTime.Now.ToString("O"), state = "Pending",
                entries = moves.Select(x => new VfxOrganizerJournalEntry { guid = x.resource.guid, original = x.resource.path, destination = x.destination }).ToList() };
            if (reverse.entries.Count > 0)
            {
                string recovery = Path.Combine(JournalFolder, "restore-" + Guid.NewGuid().ToString("N") + ".json");
                Directory.CreateDirectory(JournalFolder);
                SaveJournal(recovery, reverse);
                var temporaryFolders = new List<string>();
                try { Apply(reverse.entries, false, temporaryFolders); reverse.state = "Completed"; SaveJournal(recovery, reverse); }
                catch
                {
                    try { Apply(reverse.entries, true, temporaryFolders); reverse.state = "RolledBack"; }
                    catch { reverse.state = "RecoveryRequired"; throw; }
                    finally { SaveJournal(recovery, reverse); }
                    throw;
                }
                finally { foreach (string folder in temporaryFolders) DeleteEmptyFolder(folder); }
            }
            journal.state = "Restored";
            SaveJournal(file, journal);
        }

        private static void Apply(List<VfxOrganizerJournalEntry> entries, bool toOriginal, List<string> temporaryFolders)
        {
            string staging = "Assets/__VfxOrganizer_" + Guid.NewGuid().ToString("N");
            var active = entries.Where(x => AssetDatabase.GUIDToAssetPath(x.guid) != (toOriginal ? x.original : x.destination)).ToList();
            if (active.Count == 0) return;
            temporaryFolders.Add(staging);
            EnsureFolder(staging);
            try
            {
                foreach (var entry in active) EnsureFolder(Path.GetDirectoryName(toOriginal ? entry.original : entry.destination).Replace('\\', '/'));
                var currentPaths = active.ToDictionary(x => x.guid, x => AssetDatabase.GUIDToAssetPath(x.guid));
                AssetDatabase.StartAssetEditing();
                try
                {
                    foreach (var entry in active)
                        Move(currentPaths[entry.guid], staging + "/" + entry.guid + Path.GetExtension(entry.original));
                }
                finally { AssetDatabase.StopAssetEditing(); }
                // Unity 2022.3 must import the staged paths before they can move again.
                AssetDatabase.StartAssetEditing();
                try
                {
                    foreach (var entry in active) Move(staging + "/" + entry.guid + Path.GetExtension(entry.original), toOriginal ? entry.original : entry.destination);
                }
                finally { AssetDatabase.StopAssetEditing(); }
            }
            finally
            {
                // Never delete a staging folder containing an asset after a partial failure.
                DeleteEmptyFolder(staging);
            }
            foreach (var entry in entries)
                if (AssetDatabase.GUIDToAssetPath(entry.guid) != (toOriginal ? entry.original : entry.destination))
                    throw new InvalidOperationException(CHToolLanguage.Text("移动后的 GUID 路径校验失败：") + entry.guid);
        }

        private static void DeleteEmptyFolder(string path)
        {
            if (AssetDatabase.IsValidFolder(path) && Directory.Exists(path) && !Directory.EnumerateFileSystemEntries(path).Any()) AssetDatabase.DeleteAsset(path);
        }

        private static void Move(string source, string destination)
        {
            if (string.IsNullOrEmpty(source)) throw new InvalidOperationException(CHToolLanguage.Text("移动的源资源已不存在。"));
            string error = AssetDatabase.MoveAsset(source, destination);
            if (!string.IsNullOrEmpty(error)) throw new IOException(source + " → " + destination + "：" + error);
        }

        private static void ValidateMoves(IList<VfxResourceMove> moves)
        {
            var sources = new HashSet<string>(moves.Select(x => x.resource.path), Paths);
            var destinations = new HashSet<string>(Paths);
            foreach (var move in moves)
            {
                if (!string.IsNullOrEmpty(Protection(move.resource.path))) throw new InvalidOperationException(CHToolLanguage.Text("源资源路径受保护：") + move.resource.path);
                ValidateAssetFolder(Path.GetDirectoryName(move.destination).Replace('\\', '/'));
                ValidateName(Path.GetFileNameWithoutExtension(move.destination), CHToolLanguage.Text("目标文件名"));
                if (!destinations.Add(move.destination)) throw new InvalidOperationException(CHToolLanguage.Text("多个资源指向同一路径：") + move.destination);
                if (AssetDatabase.AssetPathToGUID(move.resource.path, AssetPathToGUIDOptions.OnlyExistingAssets) != move.resource.guid) throw new InvalidOperationException(CHToolLanguage.Text("资源位置已变化，请重新扫描：") + move.resource.path);
                if ((!string.IsNullOrEmpty(AssetDatabase.AssetPathToGUID(move.destination, AssetPathToGUIDOptions.OnlyExistingAssets)) || File.Exists(move.destination) || Directory.Exists(move.destination)) && !sources.Contains(move.destination))
                    throw new InvalidOperationException(CHToolLanguage.Text("目标路径已存在，请修改命名或目录：") + move.destination);
                if (!AssetDatabase.IsOpenForEdit(move.resource.path, StatusQueryOptions.ForceUpdate) || IsReadOnly(move.resource.path) || IsReadOnly(move.resource.path + ".meta"))
                    throw new InvalidOperationException(CHToolLanguage.Text("资源或 .meta 只读 / 未签出：") + move.resource.path);
                if (AssetDatabase.LoadAllAssetsAtPath(move.resource.path).Any(x => x != null && EditorUtility.IsDirty(x)))
                    throw new InvalidOperationException(CHToolLanguage.Text("资源有尚未保存的修改，请先保存后重新扫描：") + move.resource.path);
                string parent = Path.GetDirectoryName(move.destination).Replace('\\', '/');
                while (!string.IsNullOrEmpty(parent) && parent != "Assets")
                {
                    if (File.Exists(parent)) throw new InvalidOperationException(CHToolLanguage.Text("目标目录被文件占用：") + parent);
                    parent = Path.GetDirectoryName(parent).Replace('\\', '/');
                }
            }
        }

        private static bool IsReadOnly(string path) { return File.Exists(path) && (File.GetAttributes(path) & FileAttributes.ReadOnly) != 0; }
        private static void SaveJournal(string file, VfxOrganizerJournal journal) { File.WriteAllText(file, JsonUtility.ToJson(journal, true)); }

        internal static void EnsureFolder(string path)
        {
            if (AssetDatabase.IsValidFolder(path)) return;
            string parent = Path.GetDirectoryName(path).Replace('\\', '/');
            EnsureFolder(parent);
            string guid = AssetDatabase.CreateFolder(parent, Path.GetFileName(path));
            if (string.IsNullOrEmpty(guid)) throw new IOException(CHToolLanguage.Text("无法创建资源目录：") + path);
        }

        private static void ValidateAssetFolder(string path)
        {
            if (path != "Assets" && !path.StartsWith("Assets/", StringComparison.Ordinal)) throw new InvalidOperationException(CHToolLanguage.Text("目标目录必须位于当前工程的 Assets 下。"));
            ValidateRelativeFolder(path);
            foreach (string segment in path.Split('/'))
                if (IsSpecialFolder(segment)) throw new InvalidOperationException(CHToolLanguage.Text("整理目标不能进入 Unity 特殊目录：") + segment);
        }

        private static void ValidateRelativeFolder(string folder)
        {
            if (folder == "") return;
            if (folder == null || folder.StartsWith("/", StringComparison.Ordinal) || folder.Contains("\\")) throw new InvalidOperationException(CHToolLanguage.Text("分类目录请使用相对路径和 / 分隔符。"));
            foreach (string segment in folder.Split('/')) ValidateName(segment, CHToolLanguage.Text("目录名"));
        }

        private static void ValidateName(string name, string label)
        {
            string deviceName = (name ?? "").Split('.')[0];
            if (string.IsNullOrWhiteSpace(name) || name != name.Trim() || name.StartsWith(".", StringComparison.Ordinal) || name.EndsWith("~", StringComparison.Ordinal) || name.EndsWith(".", StringComparison.Ordinal) ||
                name.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0 || name.Any(char.IsControl) ||
                Regex.IsMatch(deviceName, @"^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$", RegexOptions.IgnoreCase))
                throw new InvalidOperationException(label + CHToolLanguage.Text("包含无效字符或保留名称：") + name);
        }

        private static bool IsSpecialFolder(string segment)
        {
            return new[] { "Editor", "Resources", "StreamingAssets", "Plugins", "Gizmos", "Editor Default Resources", "Standard Assets" }.Contains(segment, Paths) || segment.EndsWith("~", StringComparison.Ordinal);
        }

        private static string Protection(string path)
        {
            if (!path.StartsWith("Assets/", StringComparison.Ordinal)) return CHToolLanguage.Text("内置或 Packages 资源");
            if (path.Split('/').Any(IsSpecialFolder)) return CHToolLanguage.Text("Unity 特殊目录，保留路径语义");
            string extension = Path.GetExtension(path).ToLowerInvariant();
            if (new[] { ".cs", ".dll", ".asmdef", ".asmref", ".cginc", ".hlsl", ".compute", ".unity" }.Contains(extension)) return CHToolLanguage.Text("代码、Shader include 或场景文件");
            return null;
        }

        private static VfxResourceKind Classify(string path)
        {
            Type type = AssetDatabase.GetMainAssetTypeAtPath(path);
            if (type == null) return VfxResourceKind.Other;
            if (typeof(Texture).IsAssignableFrom(type) || type == typeof(Sprite)) return VfxResourceKind.Texture;
            if (typeof(Material).IsAssignableFrom(type)) return VfxResourceKind.Material;
            if (AssetImporter.GetAtPath(path) is ModelImporter || typeof(Mesh).IsAssignableFrom(type)) return VfxResourceKind.Model;
            if (typeof(AnimationClip).IsAssignableFrom(type)) return VfxResourceKind.Animation;
            if (typeof(RuntimeAnimatorController).IsAssignableFrom(type)) return VfxResourceKind.Controller;
            if (typeof(GameObject).IsAssignableFrom(type)) return VfxResourceKind.Prefab;
            if (typeof(AudioClip).IsAssignableFrom(type)) return VfxResourceKind.Audio;
            if (typeof(Shader).IsAssignableFrom(type)) return VfxResourceKind.Shader;
            return VfxResourceKind.Other;
        }
    }
}
