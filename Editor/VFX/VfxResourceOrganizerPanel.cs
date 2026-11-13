using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools.VFX
{
    [Serializable]
    internal sealed class VfxResourceOrganizerPanel
    {
        [SerializeField] private List<GameObject> targets = new List<GameObject>();
        [SerializeField] private VfxOrganizerSettings settings = new VfxOrganizerSettings();
        [SerializeField] private List<string> excluded = new List<string>();
        [SerializeField] private string lastJournal;
        [SerializeField] private bool rulesExpanded = true;
        [SerializeField] private int settingsVersion;
        [SerializeField] private List<VfxResourceKind> namingExpanded = new List<VfxResourceKind> { VfxResourceKind.Texture };
        private VfxResourceScan scan;
        private VfxResourcePlan plan;
        private Vector2 scroll, resourceScroll;
        private CHToolMessage status;
        private string filter = "";
        private MessageType statusType;
        private static string PreferenceKey { get { return "VfxResourceOrganizer.Settings." + Hash128.Compute(Application.dataPath.ToLowerInvariant()); } }

        [NonSerialized] private Action repaint;
        private void Repaint() { if (repaint != null) repaint(); }

        internal void Enable(Action repaintHost)
        {
            if (settingsVersion == 0 && EditorPrefs.HasKey(PreferenceKey))
            {
                try { settings = VfxOrganizerPresets.Deserialize(EditorPrefs.GetString(PreferenceKey)); }
                catch (Exception error) { SetStatus(new CHToolMessage(CHToolLanguage.Text(true, "上次的设置未能载入：") + error.Message, CHToolLanguage.Text(false, "上次的设置未能载入：") + error.Message), MessageType.Warning); }
            }
            if (settingsVersion < 1)
            {
                foreach (var rule in settings.rules)
                    if (rule.kind == VfxResourceKind.Prefab && rule.prefix == "FX") rule.prefix = "Prafabs";
            }
            settingsVersion = 2;
            repaint = repaintHost;
            EditorApplication.projectChanged -= InvalidateScan;
            EditorApplication.hierarchyChanged -= InvalidateScan;
            EditorApplication.projectChanged += InvalidateScan;
            EditorApplication.hierarchyChanged += InvalidateScan;
        }

        internal void Disable()
        {
            RememberSettings();
            EditorApplication.projectChanged -= InvalidateScan;
            EditorApplication.hierarchyChanged -= InvalidateScan;
        }

        private void InvalidateScan() { scan = null; plan = null; Repaint(); }

        internal void AddSelection()
        {
            foreach (GameObject target in Selection.gameObjects)
                if (!targets.Contains(target)) targets.Add(target);
            SuggestEffectName();
            InvalidateScan();
        }

        private void SuggestEffectName()
        {
            var first = targets.FirstOrDefault(x => x != null);
            if (first != null && (string.IsNullOrWhiteSpace(settings.effectName) || settings.effectName == "Effect"))
            {
                settings.effectName = first.name;
                RememberSettings();
            }
        }

        private void RememberSettings()
        {
            try { EditorPrefs.SetString(PreferenceKey, VfxOrganizerPresets.Serialize(settings)); }
            catch (Exception error) { Debug.LogWarning(CHToolLanguage.Text("资源整理设置未保存：") + error.Message); }
        }

        internal void DrawPanel()
        {
            float oldLabelWidth = EditorGUIUtility.labelWidth;
            EditorGUIUtility.labelWidth = 145;
            scroll = EditorGUILayout.BeginScrollView(scroll);
            try
            {
                GUILayout.Space(8);
                GUILayout.Label(CHToolLanguage.Text("特效引用资源整理"), new GUIStyle(EditorStyles.boldLabel) { fontSize = 20 });
                EditorGUILayout.LabelField(CHToolLanguage.Text("选择特效 → 扫描递归引用 → 设置分类和命名 → 预览并执行"), EditorStyles.wordWrappedLabel);
                DrawTargets();
                if (GUILayout.Button(CHToolLanguage.Text("1. 扫描特效引用"), GUILayout.Height(30))) Run(() =>
                {
                    scan = VfxResourceOrganizer.Scan(targets, amount => EditorUtility.DisplayCancelableProgressBar(CHToolLanguage.Text("扫描特效引用"), CHToolLanguage.Text("检查当前工程中其他资源的共用引用"), amount));
                    plan = null;
                    try
                    {
                        plan = VfxResourceOrganizer.BuildPlan(scan, settings, new HashSet<string>(excluded));
                        SetStatus(new CHToolMessage(CHToolLanguage.Text(true, "扫描完成，已自动生成预览：") + scan.entries.Count + CHToolLanguage.Text(true, " 个文件；可整理 ") + plan.moves.Count + CHToolLanguage.Text(true, " 个。"), CHToolLanguage.Text(false, "扫描完成，已自动生成预览：") + scan.entries.Count + CHToolLanguage.Text(false, " 个文件；可整理 ") + plan.moves.Count + CHToolLanguage.Text(false, " 个。")), MessageType.Info);
                    }
                    catch (Exception error)
                    {
                        SetStatus(new CHToolMessage(CHToolLanguage.Text(true, "扫描完成，但预览未生成：") + error.Message + CHToolLanguage.Text(true, "。请修正设置后点击“2. 生成整理预览”。"), CHToolLanguage.Text(false, "扫描完成，但预览未生成：") + error.Message + CHToolLanguage.Text(false, "。请修正设置后点击“2. 生成整理预览”。")), MessageType.Warning);
                    }
                });
                EditorGUI.BeginChangeCheck();
                DrawSettings();
                if (EditorGUI.EndChangeCheck()) { plan = null; RememberSettings(); }
                using (new EditorGUI.DisabledScope(scan == null))
                {
                    if (GUILayout.Button(CHToolLanguage.Text("2. 生成整理预览"), GUILayout.Height(28))) Run(() =>
                    {
                        plan = null;
                        plan = VfxResourceOrganizer.BuildPlan(scan, settings, new HashSet<string>(excluded));
                        SetStatus(new CHToolMessage(CHToolLanguage.Text(true, "预览已生成，将移动 / 重命名 ") + plan.moves.Count + CHToolLanguage.Text(true, " 个文件。"), CHToolLanguage.Text(false, "预览已生成，将移动 / 重命名 ") + plan.moves.Count + CHToolLanguage.Text(false, " 个文件。")), MessageType.Info);
                    });
                }
                if (scan != null) DrawResources();
                else EditorGUILayout.HelpBox(CHToolLanguage.Text("添加物体后扫描。资源或层级变化后需要重新扫描；执行时还会复查实际引用。"), MessageType.Info);
                EditorGUILayout.HelpBox(CHToolLanguage.Text("移动保留 GUID。共用检测覆盖资源的序列化引用和已加载场景；按路径字符串加载的资源需自行排除。移动不使用 Ctrl+Z，请用整理记录恢复路径。"), MessageType.Info);
                if (scan != null && plan == null)
                    EditorGUILayout.HelpBox(CHToolLanguage.Text("已完成扫描，但还没有有效的整理预览。请点击“2. 生成整理预览”；如果仍失败，请先处理上方提示的冲突、只读或未保存修改。"), MessageType.Warning);
                else if (plan != null && plan.moves.Count == 0)
                    EditorGUILayout.HelpBox(CHToolLanguage.Text("预览已生成，但没有可移动的文件。请检查资源清单中的“入口预制体保留 / 共用资源保留 / 此类型未启用 / 手动排除”，或打开相应选项。"), MessageType.Info);
                using (new EditorGUI.DisabledScope(plan == null || plan.moves.Count == 0 || EditorApplication.isPlayingOrWillChangePlaymode))
                    if (GUILayout.Button(CHToolLanguage.Text("3. 执行预览中的整理（") + (plan == null ? 0 : plan.moves.Count) + CHToolLanguage.Text(" 个文件）"), GUILayout.Height(32))) Run(Execute);
                using (new EditorGUILayout.HorizontalScope())
                {
                    using (new EditorGUI.DisabledScope(string.IsNullOrEmpty(lastJournal) || !File.Exists(lastJournal)))
                        if (GUILayout.Button(CHToolLanguage.Text("恢复上次整理的路径"))) Run(() => Restore(lastJournal));
                    if (GUILayout.Button(CHToolLanguage.Text("选择整理记录恢复…"))) Run(() =>
                    {
                        string file = EditorUtility.OpenFilePanel(CHToolLanguage.Text("选择当前工程的整理记录"), VfxResourceOrganizer.JournalFolder, "json");
                        if (!string.IsNullOrEmpty(file)) Restore(file);
                    });
                }
                if (!string.IsNullOrEmpty(status)) EditorGUILayout.HelpBox(status, statusType);
            }
            finally
            {
                EditorGUILayout.EndScrollView();
                EditorGUIUtility.labelWidth = oldLabelWidth;
            }
        }

        private void DrawTargets()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                GUILayout.Label(CHToolLanguage.Text("特效入口（包含 inactive 子级、嵌套预制体和间接引用）"), EditorStyles.boldLabel);
                for (int i = 0; i < targets.Count; i++)
                    using (new EditorGUILayout.HorizontalScope())
                    {
                        EditorGUI.BeginChangeCheck();
                        var target = (GameObject)EditorGUILayout.ObjectField(targets[i], typeof(GameObject), true);
                        if (EditorGUI.EndChangeCheck()) { targets[i] = target; SuggestEffectName(); InvalidateScan(); }
                        if (GUILayout.Button(CHToolLanguage.Text("移除"), GUILayout.Width(45))) { targets.RemoveAt(i--); InvalidateScan(); }
                    }
                Rect drop = GUILayoutUtility.GetRect(0, 32, GUILayout.ExpandWidth(true));
                GUI.Box(drop, CHToolLanguage.Text("把特效预制体或场景物体拖到这里"));
                Event current = Event.current;
                if (drop.Contains(current.mousePosition) && (current.type == EventType.DragUpdated || current.type == EventType.DragPerform))
                {
                    DragAndDrop.visualMode = DragAndDropVisualMode.Copy;
                    if (current.type == EventType.DragPerform)
                    {
                        DragAndDrop.AcceptDrag();
                        foreach (var item in DragAndDrop.objectReferences)
                        {
                            var gameObject = item as GameObject;
                            if (gameObject != null && !targets.Contains(gameObject)) targets.Add(gameObject);
                        }
                        SuggestEffectName();
                        InvalidateScan();
                    }
                    current.Use();
                }
                using (new EditorGUILayout.HorizontalScope())
                {
                    if (GUILayout.Button(CHToolLanguage.Text("加入当前选择"))) AddSelection();
                    if (GUILayout.Button(CHToolLanguage.Text("添加空入口"))) { targets.Add(null); InvalidateScan(); }
                    if (GUILayout.Button(CHToolLanguage.Text("清空"))) { targets.Clear(); excluded.Clear(); InvalidateScan(); }
                }
            }
        }

        private void DrawSettings()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    GUILayout.Label(CHToolLanguage.Text("分类目录与命名"), EditorStyles.boldLabel);
                    if (GUILayout.Button(CHToolLanguage.Text("保存整理方案…"), GUILayout.Width(115))) Run(SavePreset);
                    if (GUILayout.Button(CHToolLanguage.Text("载入整理方案…"), GUILayout.Width(115))) Run(LoadPreset);
                }
                EditorGUILayout.LabelField(CHToolLanguage.Text("目录与命名会按工程记住；整理方案可以保存多套配置，反复载入使用。"), EditorStyles.wordWrappedMiniLabel);
                settings.effectName = EditorGUILayout.TextField(CHToolLanguage.Text("特效名"), settings.effectName);
                using (new EditorGUILayout.HorizontalScope())
                {
                    settings.destination = FolderField(CHToolLanguage.Text("默认根目录"), settings.destination);
                    if (GUILayout.Button(CHToolLanguage.Text("选择…"), GUILayout.Width(60)))
                        Run(() => ChooseFolder(CHToolLanguage.Text("选择默认根目录"), settings.destination, path => settings.destination = path));
                }
                EditorGUILayout.LabelField(CHToolLanguage.Text("每种资源都可以单独选择 Assets 下的目标目录；尚未单独设置的类型跟随默认根目录。"), EditorStyles.wordWrappedMiniLabel);
                settings.includeRoots = EditorGUILayout.Toggle(CHToolLanguage.Text("同时整理入口预制体"), settings.includeRoots);
                settings.includeShared = EditorGUILayout.Toggle(CHToolLanguage.Text("允许整理共用资源"), settings.includeShared);
                if (settings.includeShared) EditorGUILayout.HelpBox(CHToolLanguage.Text("共用资源移动后，其他特效的 GUID 引用也会指向新位置。请核对预览中的“共用来源”。"), MessageType.Warning);
                rulesExpanded = EditorGUILayout.Foldout(rulesExpanded, CHToolLanguage.Text("各类资源的目录和命名方式"), true);
                if (rulesExpanded)
                {
                    foreach (var rule in settings.rules)
                        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
                        {
                            string folder;
                            try { folder = VfxResourceOrganizer.ResolveDestinationFolder(settings, rule); }
                            catch (Exception) { folder = rule.folder ?? ""; }
                            using (new EditorGUILayout.HorizontalScope())
                            {
                                int count = scan == null ? -1 : scan.entries.Count(x => x.kind == rule.kind);
                                rule.enabled = EditorGUILayout.ToggleLeft(CHToolLanguage.Text(VfxResourceOrganizer.KindNames[(int)rule.kind]) + (count < 0 ? "" : " (" + count + ")"), rule.enabled, GUILayout.Width(130));
                                EditorGUI.BeginChangeCheck();
                                string edited = FolderField(null, rule.folder ?? "");
                                if (EditorGUI.EndChangeCheck()) rule.folder = edited;
                                if (GUILayout.Button(CHToolLanguage.Text("选择…"), GUILayout.Width(55)))
                                    Run(() => ChooseFolder(CHToolLanguage.Text("选择") + CHToolLanguage.Text(VfxResourceOrganizer.KindNames[(int)rule.kind]) + CHToolLanguage.Text("目录"), folder, path => rule.folder = path));
                                if (GUILayout.Button(new GUIContent(CHToolLanguage.Text("默认"), CHToolLanguage.Text("恢复为默认根目录下的类型子目录")), GUILayout.Width(42)))
                                {
                                    rule.folder = new VfxOrganizerSettings().rules.First(x => x.kind == rule.kind).folder;
                                    plan = null;
                                    GUI.changed = true;
                                }
                            }
                            EditorGUILayout.LabelField(CHToolLanguage.Text("目标目录：") + folder, EditorStyles.wordWrappedMiniLabel);
                            bool open = namingExpanded.Contains(rule.kind);
                            string namingLabel = NamingChoices()[VfxResourceNaming.GetChoice(rule)];
                            bool updated = EditorGUILayout.Foldout(open, CHToolLanguage.Text("命名方式：") + namingLabel, true);
                            if (updated != open)
                            {
                                if (updated) namingExpanded.Add(rule.kind); else namingExpanded.Remove(rule.kind);
                            }
                            if (updated) DrawNaming(rule);
                            else DrawNamingExamples(rule);
                        }
                    EditorGUILayout.LabelField(CHToolLanguage.Text("选择命名方式后，下面会直接显示结果。序号按类型从 001、002、003 开始，文件扩展名自动保留。"), EditorStyles.wordWrappedMiniLabel);
                    EditorGUILayout.LabelField(CHToolLanguage.Text("Shader / 其他资源默认不整理。含路径引用的 Shader 请先核对 include 路径。模型内嵌资源随模型文件整体移动。"), EditorStyles.wordWrappedMiniLabel);
                }
            }
        }

        private void DrawNaming(VfxResourceRule rule)
        {
            int currentChoice = VfxResourceNaming.GetChoice(rule);
            int selectedChoice = EditorGUILayout.Popup(CHToolLanguage.Text("命名方式"), currentChoice, NamingChoices());
            if (selectedChoice != currentChoice) VfxResourceNaming.SetChoice(rule, selectedChoice);
            using (new EditorGUI.DisabledScope(!(rule.pattern ?? "").Contains("{prefix}")))
                rule.prefix = EditorGUILayout.TextField(new GUIContent(CHToolLanguage.Text("文件名前缀"), CHToolLanguage.Text("自动加在文件名开头的文字。例如材质 M、贴图 T、预制体 Prafabs。")), rule.prefix);
            if (VfxResourceNaming.GetChoice(rule) == VfxResourceNaming.Choices.Length - 1)
            {
                VfxNameBuilder.Draw(rule);
            }
            DrawNamingExamples(rule);
        }

        private static string[] NamingChoices()
        {
            var choices=CHToolLanguage.Text(VfxResourceNaming.Choices);
            choices[choices.Length-1]=CHToolLanguage.Pick("自定义组合","Custom combination");
            return choices;
        }

        private void DrawNamingExamples(VfxResourceRule rule)
        {
            var examples = scan == null ? new VfxResourceEntry[0] : scan.entries.Where(x => x.kind == rule.kind &&
                string.IsNullOrEmpty(x.protection) && (!x.isRoot || settings.includeRoots) &&
                (x.externalUsers.Count == 0 || settings.includeShared) && !excluded.Contains(x.guid)).Take(2).ToArray();
            string[] extensions = { ".png", ".mat", ".fbx", ".anim", ".controller", ".prefab", ".wav", ".shader", ".asset" };
            try
            {
                var names = new List<string>();
                int count = Math.Max(1, examples.Length);
                for (int i = 0; i < count; i++)
                {
                    string original = examples.Length > i ? Path.GetFileNameWithoutExtension(examples[i].path) : "Spark";
                    string extension = examples.Length > i ? Path.GetExtension(examples[i].path) : extensions[(int)rule.kind];
                    string result = VfxResourceOrganizer.ExpandName(rule.pattern, rule.prefix, settings.effectName, original, i + 1) + extension;
                    names.Add(examples.Length > i ? Path.GetFileName(examples[i].path) + "  →  " + result : result);
                }
                EditorGUILayout.LabelField((examples.Length == 0 ? CHToolLanguage.Text("生成示例：") : CHToolLanguage.Text("改名预览：")) + string.Join("；", names), EditorStyles.wordWrappedLabel);
            }
            catch (Exception error) { EditorGUILayout.HelpBox(error.Message, MessageType.Warning); }
        }

        private string FolderField(string label, string value)
        {
            string edited = label == null ? EditorGUILayout.TextField(value) : EditorGUILayout.TextField(label, value);
            Rect rect = GUILayoutUtility.GetLastRect();
            Event current = Event.current;
            if (rect.Contains(current.mousePosition) && (current.type == EventType.DragUpdated || current.type == EventType.DragPerform))
            {
                string path = DragAndDrop.objectReferences.Length == 1 ? AssetDatabase.GetAssetPath(DragAndDrop.objectReferences[0]) : "";
                bool folder = AssetDatabase.IsValidFolder(path);
                DragAndDrop.visualMode = folder ? DragAndDropVisualMode.Copy : DragAndDropVisualMode.Rejected;
                if (folder && current.type == EventType.DragPerform)
                {
                    DragAndDrop.AcceptDrag();
                    try { edited = VfxResourceOrganizer.ToAssetFolderPath(Path.GetFullPath(path)); plan = null; GUI.changed = true; }
                    catch (Exception error) { SetStatus(error.Message, MessageType.Error); }
                }
                current.Use();
            }
            return edited;
        }

        private void SavePreset()
        {
            string folder = Path.Combine(VfxResourceOrganizer.JournalFolder, "Presets");
            Directory.CreateDirectory(folder);
            string path = EditorUtility.SaveFilePanel(CHToolLanguage.Text("保存分类目录和命名方案"), folder, "VFX整理方案", "json");
            if (string.IsNullOrEmpty(path)) return;
            File.WriteAllText(path, VfxOrganizerPresets.Serialize(settings));
            SetStatus(new CHToolMessage(CHToolLanguage.Text(true, "已保存整理方案：") + path, CHToolLanguage.Text(false, "已保存整理方案：") + path), MessageType.Info);
        }

        private void LoadPreset()
        {
            string path = EditorUtility.OpenFilePanel(CHToolLanguage.Text("载入分类目录和命名方案"), Path.Combine(VfxResourceOrganizer.JournalFolder, "Presets"), "json");
            if (string.IsNullOrEmpty(path)) return;
            var loaded = VfxOrganizerPresets.Deserialize(File.ReadAllText(path));
            settings = loaded;
            excluded.Clear();
            plan = null;
            RememberSettings();
            GUI.changed = true;
            SetStatus(new CHToolMessage(CHToolLanguage.Text(true, "已载入整理方案，请核对目标目录并重新生成预览。"), CHToolLanguage.Text(false, "已载入整理方案，请核对目标目录并重新生成预览。")), MessageType.Info);
        }

        private void ChooseFolder(string title, string current, Action<string> assign)
        {
            string initial = Application.dataPath;
            if (!string.IsNullOrEmpty(current))
            {
                string candidate = Path.Combine(Path.GetDirectoryName(Application.dataPath), current);
                if (Directory.Exists(candidate)) initial = candidate;
            }
            string selected = EditorUtility.OpenFolderPanel(title, initial, "");
            if (string.IsNullOrEmpty(selected)) return;
            assign(VfxResourceOrganizer.ToAssetFolderPath(selected));
            plan = null;
            GUI.changed = true;
        }

        private void DrawResources()
        {
            using (new EditorGUILayout.HorizontalScope())
            {
                GUILayout.Label(CHToolLanguage.Text("引用清单 / 路径预览"), EditorStyles.boldLabel);
                filter = EditorGUILayout.TextField(filter, EditorStyles.toolbarSearchField, GUILayout.Width(210));
                if (GUILayout.Button(CHToolLanguage.Text("选中可整理项"), GUILayout.Width(100))) { excluded.Clear(); plan = null; }
                if (GUILayout.Button(CHToolLanguage.Text("全部排除"), GUILayout.Width(75))) { excluded = scan.entries.Select(x => x.guid).ToList(); plan = null; }
            }
            var destinations = plan == null ? new Dictionary<string, string>() : plan.moves.ToDictionary(x => x.resource.guid, x => x.destination);
            resourceScroll = EditorGUILayout.BeginScrollView(resourceScroll, GUILayout.Height(260));
            try
            {
                foreach (var entry in scan.entries)
                {
                    if (!string.IsNullOrEmpty(filter) && entry.path.IndexOf(filter, StringComparison.OrdinalIgnoreCase) < 0 &&
                        CHToolLanguage.Text(VfxResourceOrganizer.KindNames[(int)entry.kind]).IndexOf(filter, StringComparison.OrdinalIgnoreCase) < 0) continue;
                    var rule = settings.rules.FirstOrDefault(x => x.kind == entry.kind);
                    string reason = entry.protection;
                    if (string.IsNullOrEmpty(reason) && entry.isRoot && !settings.includeRoots) reason = CHToolLanguage.Text("入口预制体保留");
                    if (string.IsNullOrEmpty(reason) && entry.externalUsers.Count > 0 && !settings.includeShared) reason = CHToolLanguage.Text("共用资源保留");
                    if (string.IsNullOrEmpty(reason) && (rule == null || !rule.enabled)) reason = CHToolLanguage.Text("此类型未启用");
                    bool selected = !excluded.Contains(entry.guid);
                    using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
                    {
                        using (new EditorGUILayout.HorizontalScope())
                        {
                            using (new EditorGUI.DisabledScope(!string.IsNullOrEmpty(reason)))
                            {
                                bool updated = GUILayout.Toggle(selected && string.IsNullOrEmpty(reason), "", GUILayout.Width(18));
                                if (string.IsNullOrEmpty(reason) && updated != selected)
                                {
                                    if (updated) excluded.Remove(entry.guid); else excluded.Add(entry.guid);
                                    plan = null;
                                }
                            }
                            GUILayout.Label(CHToolLanguage.Text(VfxResourceOrganizer.KindNames[(int)entry.kind]) + " · " + Path.GetFileName(entry.path), EditorStyles.boldLabel);
                            if (GUILayout.Button(CHToolLanguage.Text("定位"), GUILayout.Width(42))) EditorGUIUtility.PingObject(AssetDatabase.LoadMainAssetAtPath(entry.path));
                        }
                        EditorGUILayout.SelectableLabel(entry.path, EditorStyles.miniLabel, GUILayout.Height(16));
                        string destination;
                        EditorGUILayout.LabelField(destinations.TryGetValue(entry.guid, out destination) ? "→ " + destination :
                            "· " + (reason ?? (selected ? CHToolLanguage.Text("等待生成预览 / 已位于目标路径") : CHToolLanguage.Text("手动排除"))), EditorStyles.wordWrappedMiniLabel);
                        if (entry.externalUsers.Count > 0)
                            EditorGUILayout.LabelField(new GUIContent(CHToolLanguage.Text("共用来源 ") + entry.externalUsers.Count + "：" + string.Join("；", entry.externalUsers.Take(2)) +
                                (entry.externalUsers.Count > 2 ? CHToolLanguage.Text(" …（悬停查看全部）") : ""), string.Join("\n", entry.externalUsers)), EditorStyles.wordWrappedMiniLabel);
                    }
                }
            }
            finally { EditorGUILayout.EndScrollView(); }
        }

        private void Execute()
        {
            if (!EditorUtility.DisplayDialog(CHToolLanguage.Text("执行资源整理"), CHToolLanguage.Text("将按预览移动 / 重命名 ") + plan.moves.Count + CHToolLanguage.Text(" 个文件。\n\n保留 GUID，不覆盖同名文件。可以通过整理记录恢复原路径。"), CHToolLanguage.Text("执行整理"), CHToolLanguage.Text("取消"))) return;
            int count = plan.moves.Count;
            lastJournal = VfxResourceOrganizer.Execute(plan, amount => EditorUtility.DisplayCancelableProgressBar(CHToolLanguage.Text("复查整理预览"), CHToolLanguage.Text("检查引用变化后执行移动"), amount));
            InvalidateScan();
            SetStatus(new CHToolMessage(CHToolLanguage.Text(true, "已整理 ") + count + CHToolLanguage.Text(true, " 个文件。恢复记录：") + lastJournal, CHToolLanguage.Text(false, "已整理 ") + count + CHToolLanguage.Text(false, " 个文件。恢复记录：") + lastJournal), MessageType.Info);
        }

        private void Restore(string file)
        {
            var journal = VfxResourceOrganizer.LoadJournal(file);
            if (!EditorUtility.DisplayDialog(CHToolLanguage.Text("恢复资源路径"), CHToolLanguage.Text("将依据 ") + journal.time + CHToolLanguage.Text(" 的记录恢复 ") + journal.entries.Count + CHToolLanguage.Text(" 个文件的原路径和名称。资源内容保持当前版本。"), CHToolLanguage.Text("恢复路径"), CHToolLanguage.Text("取消"))) return;
            VfxResourceOrganizer.Restore(file);
            InvalidateScan();
            SetStatus(new CHToolMessage(CHToolLanguage.Text(true, "已恢复整理前的路径和名称。"), CHToolLanguage.Text(false, "已恢复整理前的路径和名称。")), MessageType.Info);
        }

        private void Run(Action action)
        {
            try { action(); }
            catch (ExitGUIException) { throw; }
            catch (OperationCanceledException) { SetStatus(new CHToolMessage(CHToolLanguage.Text(true, "已取消扫描 / 复查，尚未执行移动。"), CHToolLanguage.Text(false, "已取消扫描 / 复查，尚未执行移动。")), MessageType.Info); }
            catch (Exception error) { plan = null; SetStatus(error.Message, MessageType.Error); }
            finally { EditorUtility.ClearProgressBar(); }
        }

        private void SetStatus(string message, MessageType type) { SetStatus(new CHToolMessage(message, message), type); }
        private void SetStatus(CHToolMessage message, MessageType type) { status = message; statusType = type; Repaint(); }
    }
}
