using System;
using System.Linq;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    public sealed partial class ASEShaderConverterWindow : EditorWindow
    {
        [SerializeField] private string inputPath = "", outputPath = "Assets/Converted_ASE.shader";
        [SerializeField] private string outputDirectory = "";
        [SerializeField] private int pipeline;
        [SerializeField] private int targetGraph;
        [SerializeField] private bool acceptStandardUnlitHost;
        private ShaderGraphNativeAnalysis nativeAnalysis;
        private ShaderGraphEnvironmentInfo nativeEnvironment;
        [SerializeField] private bool keepName;
        [SerializeField] private bool advanced, autoLayout = true, addComments = true, useRegisters = true;
        [SerializeField] private float longWireDistance = 1800;
        private Vector2 scroll;
        private Rect inputPathArea;
        private Rect outputPathArea;
        private Shader inputShader;
        private bool showOriginalMessages;
        private bool showKnowledge;
        private bool showTargets;
        private List<ShaderConversionAnalysis> targetAnalyses;
        private bool generationAttempted;
        private ShaderConversionAnalysis analysis;
        private AseEnvironmentInfo environment;
        private string error = "";
        private static readonly string[] PipelineNames = { "自动识别", "Built-in", "URP", "HDRP" };
        private static readonly string[] PipelineIds = { "Auto", "BuiltIn", "URP", "HDRP" };

        private void OnEnable()
        {
            titleContent = new GUIContent(CHToolLanguage.Pick("CH自定义工具集", "CH Custom Tools"));
            EnableVfxPanels();
            ShaderPackageUpdater.Changed += Repaint;
            EditorApplication.delayCall += EnsureUpdateCheck;
        }
        private void OnDisable()
        {
            DisableVfxPanels();
            ShaderPackageUpdater.Changed -= Repaint;
            EditorApplication.delayCall -= EnsureUpdateCheck;
        }
        private void EnsureUpdateCheck() { if (this != null) ShaderPackageUpdater.EnsureChecked(); }

        [MenuItem("Tools/CH自定义工具集")]
        public static void Open()
        {
            var window = ShowMain();
            window.Navigate("conversion"); window.conversionTab = 0; window.UseSelection();
        }

        [MenuItem("Assets/Shader转换器/分析并转换", true)]
        private static bool CanOpen() { return IsShaderFile(AssetDatabase.GetAssetPath(Selection.activeObject)); }
        [MenuItem("Assets/Shader转换器/分析并转换")]
        private static void OpenSelected() { Open(); }

        private void DrawConversionPage()
        {
            int next = GUILayout.Toolbar(conversionTab, new[]{CHToolLanguage.Pick("转换设置","Conversion settings"),CHToolLanguage.Pick("分析报告","Analysis report"),CHToolLanguage.Pick("环境检查","Environment")});
            if (next != conversionTab) { conversionTab = next; scroll = Vector2.zero; GUI.FocusControl(null); }
            scroll = EditorGUILayout.BeginScrollView(scroll);
            if (!string.IsNullOrEmpty(error)) EditorGUILayout.HelpBox(error, MessageType.Error);
            if (conversionTab == 0) DrawConversionControls();
            else if (conversionTab == 1) DrawConversionReport();
            else
            {
                if (GUILayout.Button(CHToolLanguage.Text("检查环境"))) CheckEnvironment();
                if (environment == null && nativeEnvironment == null) EditorGUILayout.HelpBox(CHToolLanguage.Pick("按当前输出格式与目标管线检查项目环境。", "Check the project for the selected output format and target pipeline."), MessageType.Info);
                DrawEnvironment();
            }
            EditorGUILayout.EndScrollView();
        }
        private void DrawConversionControls()
        {
            DrawInput();
            EditorGUI.BeginChangeCheck();
            targetGraph = EditorGUILayout.Popup(CHToolLanguage.Text("输出图格式"),targetGraph,new[]{"ASE","ShaderGraph"});
            if (EditorGUI.EndChangeCheck()) { ClearAnalysis(); SuggestOutputPath(IsShaderFile(inputPath) ? inputPath : null); }
            if (targetGraph == 1)
            {
                EditorGUI.BeginChangeCheck();
                acceptStandardUnlitHost = EditorGUILayout.ToggleLeft(CHToolLanguage.Pick("使用目标管线的标准 Unlit 宿主（雾、曝光、附加 Pass 由目标管线决定）", "Use the target pipeline's standard Unlit host (pipeline fog, exposure and auxiliary passes)"),acceptStandardUnlitHost);
                if (EditorGUI.EndChangeCheck()) ClearAnalysis();
                EditorGUILayout.HelpBox(CHToolLanguage.Pick("支持 Built-in / URP / HDRP 标准不透明 Unlit，需 Unity 2022.3、Shader Graph 14.0.8；URP / HDRP 需对应管线 14.0.8。手写输入要求 Alpha 恒为 1；支持数学、Float/Range/Vector、2D 采样、直接 UV、已适配的 Enum 关键词。Color、复杂顶点及其他渲染状态仍需适配；不代表原宿主或场景等价。", "Built-in / URP / HDRP standard opaque Unlit: Unity 2022.3, Shader Graph 14.0.8 and matching URP / HDRP 14.0.8. Input Alpha must be provably 1. Supports math, Float/Range/Vector, 2D sampling, direct UV and adapted Enum keywords. Color, complex vertex and other render states require adapters; source host/scene equivalence is not implied."),MessageType.None);
            }
            EditorGUILayout.BeginHorizontal();
            Rect outputArea = EditorGUILayout.GetControlRect();
            outputPathArea = new Rect(GUIUtility.GUIToScreenPoint(outputArea.position) - position.position, outputArea.size);
            HandleOutputDirectoryDrop(outputArea);
            string editedOutput = EditorGUI.TextField(outputArea, new GUIContent(CHToolLanguage.Text("输出 Shader"), CHToolLanguage.Pick("可拖入 Project 文件夹选择输出目录", "Drop a Project folder to select the output directory")), outputPath);
            if (editedOutput != outputPath) { outputPath = editedOutput; RememberOutputDirectory(); }
            if (GUILayout.Button(CHToolLanguage.Text("选择"), GUILayout.Width(60)))
            {
                string chosen = EditorUtility.SaveFilePanelInProject(CHToolLanguage.Text("保存转换图"), targetGraph == 0 ? "Converted_ASE" : "Converted_SG", targetGraph == 0 ? "shader" : "shadergraph", CHToolLanguage.Text("选择新的输出文件"));
                if (!string.IsNullOrEmpty(chosen)) { outputPath = chosen; RememberOutputDirectory(); }
            }
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.LabelField(CHToolLanguage.Pick("可将 Project 文件夹拖到上方输出路径栏，保留文件名并避开重名。", "Drop a Project folder onto the output path to keep the filename and avoid existing files."), EditorStyles.wordWrappedMiniLabel);
            EditorGUI.BeginChangeCheck();
            int previousPipeline = pipeline;
            pipeline = EditorGUILayout.Popup(CHToolLanguage.Text("目标管线"), pipeline, CHToolLanguage.Text(PipelineNames));
            if (pipeline != previousPipeline) acceptStandardUnlitHost = false;
            if(targetGraph == 0) keepName = EditorGUILayout.Toggle(CHToolLanguage.Text("保留 Shader 名称"), keepName);
            advanced = EditorGUILayout.Foldout(advanced, CHToolLanguage.Text("高级：节点排列与功能说明"), true);
            if (advanced && targetGraph == 0)
            {
                autoLayout = EditorGUILayout.Toggle(CHToolLanguage.Text("按连线顺序排列"), autoLayout);
                addComments = EditorGUILayout.Toggle(CHToolLanguage.Text("添加中文 Comment 说明"), addComments);
                useRegisters = EditorGUILayout.Toggle(CHToolLanguage.Text("长连线使用 Register / Get"), useRegisters);
                if (useRegisters) longWireDistance = Mathf.Clamp(EditorGUILayout.FloatField(CHToolLanguage.Text("长连线距离"), longWireDistance), 600, 20000);
                EditorGUILayout.HelpBox(CHToolLanguage.Text("节点按计算步骤从左到右排列。Comment 说明每步用途；长连线两端用同名 Register/Get 传递结果。"), MessageType.None);
            }
            if (EditorGUI.EndChangeCheck()) ClearAnalysis();
            EditorGUILayout.BeginHorizontal();
            using (new EditorGUI.DisabledScope(!IsShaderFile(inputPath)))
            {
                if (GUILayout.Button(CHToolLanguage.Text("分析"))) Analyze();
                using (new EditorGUI.DisabledScope(analysis != null && (analysis.report.status == "NeedsAgent" || analysis.report.existingAseGraph)))
                {
                    if (GUILayout.Button(CHToolLanguage.Text("生成并验证"))) Generate();
                }
            }
            if (GUILayout.Button(CHToolLanguage.Text("检查环境"))) CheckEnvironment();
            if (GUILayout.Button(CHToolLanguage.Text("使用选中 Shader"))) UseSelection();
            EditorGUILayout.EndHorizontal();
        }
        private void DrawConversionReport()
        {
            if (analysis == null) EditorGUILayout.HelpBox(CHToolLanguage.Pick("先在转换设置中选择源文件并分析，结果会显示在这里。", "Choose a source file and analyze it in Conversion settings to view its report here."), MessageType.Info);
            if (analysis != null)
            {
                EditorGUILayout.BeginHorizontal();
                if (GUILayout.Button(CHToolLanguage.Text("复制分析报告"))) EditorGUIUtility.systemCopyBuffer = nativeAnalysis == null ? JsonUtility.ToJson(analysis, true) : JsonUtility.ToJson(nativeAnalysis,true);
                if (GUILayout.Button(CHToolLanguage.Text("导出节点计划和报告")))
                {
                    string path = EditorUtility.SaveFilePanel(CHToolLanguage.Text("导出分析"), Application.dataPath, "shader-analysis", "json");
                    if (!string.IsNullOrEmpty(path)) File.WriteAllText(path, nativeAnalysis == null ? JsonUtility.ToJson(analysis, true) : JsonUtility.ToJson(nativeAnalysis,true));
                }
                EditorGUILayout.EndHorizontal();
            }
            if (analysis != null)
            {
                var r = analysis.report;
                EditorGUILayout.Space();
                EditorGUILayout.HelpBox(ShaderConverterMessages.Summary(r), ShaderConverterMessages.Severity(r));
                EditorGUILayout.LabelField(CHToolLanguage.Text("源管线 → 目标管线"), r.sourcePipeline + " → " + r.pipeline);
                DrawTargets();
                EditorGUILayout.LabelField(CHToolLanguage.Text("原生节点 / Custom Expression"), r.nativeNodeCount + " / " + r.customExpressionCount);
                if (generationAttempted) EditorGUILayout.LabelField("Comment / Register / Get", r.commentCount + " / " + r.registerNodeCount + " / " + r.getNodeCount);
                if (generationAttempted)
                {
                    EditorGUILayout.LabelField(targetGraph == 0 ? CHToolLanguage.Text("ASE 保存并重载") : CHToolLanguage.Text("Shader Graph 保存并重载"), (targetGraph == 0 ? r.aseRoundTripPassed : r.shaderGraphRoundTripPassed) ? CHToolLanguage.Text("通过") : CHToolLanguage.Text("未通过或未完成"));
                    EditorGUILayout.LabelField(CHToolLanguage.Text("Shader 编译"), r.shaderCompiled ? CHToolLanguage.Text("通过") : CHToolLanguage.Text("未通过或未完成"));
                    EditorGUILayout.LabelField(CHToolLanguage.Text("画面对比"), r.visualComparisonPassed ? CHToolLanguage.Text("通过") : CHToolLanguage.Text("尚未验证"));
                }
                else EditorGUILayout.LabelField(CHToolLanguage.Text("生成与验证"), CHToolLanguage.Text("尚未执行"));
                DrawKnowledge();
                DrawMessages(r.blockers, r.status == "NeedsAgent" ? CHToolLanguage.Text("需要适配的项目（仍会阻止自动生成）") : CHToolLanguage.Text("阻塞原因"), MessageType.None);
                DrawMessages(r.fallbackReasons, CHToolLanguage.Text("Custom Expression 使用原因"), MessageType.Warning);
                DrawMessages(r.warnings, CHToolLanguage.Text("说明"), MessageType.None);
                showOriginalMessages = EditorGUILayout.Foldout(showOriginalMessages, CHToolLanguage.Text("查看原始诊断"), true);
                if (showOriginalMessages)
                {
                    EditorGUILayout.LabelField(CHToolLanguage.Text("状态"), r.status);
                    DrawOriginalMessages(r.blockers);
                    DrawOriginalMessages(r.fallbackReasons);
                    DrawOriginalMessages(r.warnings);
                }
            }
        }
        private void CheckEnvironment()
        {
            if (targetGraph == 0) environment = AseEditorBridge.Probe();
            else nativeEnvironment = ShaderGraphEditorBridge.Probe(PipelineIds[pipeline]);
            conversionTab = 2; scroll = Vector2.zero;
        }
        private void DrawEnvironment()
        {
            if (targetGraph == 1 && nativeEnvironment != null) { EditorGUILayout.LabelField("Unity / ShaderGraph",nativeEnvironment.unityVersion+" / "+nativeEnvironment.shaderGraphVersion); EditorGUILayout.LabelField(CHToolLanguage.Text("当前管线"),nativeEnvironment.activePipeline); DrawMessages(nativeEnvironment.errors,CHToolLanguage.Text("环境问题"),MessageType.Error); }
            if (targetGraph == 0 && environment != null)
            {
                EditorGUILayout.LabelField("Unity / ASE", environment.unityVersion + " / " + environment.aseVersion);
                EditorGUILayout.LabelField(CHToolLanguage.Text("当前管线"), environment.activePipeline);
                DrawMessages(environment.errors, CHToolLanguage.Text("环境问题"), MessageType.Error);
                foreach (var template in environment.templates) EditorGUILayout.LabelField((template.ready ? CHToolLanguage.Text("可用：") : CHToolLanguage.Text("需导入：")) + template.name);
            }
        }

        private void Analyze()
        {
            ClearAnalysis();
            try
            {
                if (!IsShaderFile(inputPath)) throw new ArgumentException(CHToolLanguage.Pick("已选择目录，请再选择要转换的 Shader 文件。", "A folder is selected. Choose a Shader file to convert."));
                string source = File.ReadAllText(SourceDiskPath(inputPath));
                var options = new ShaderConversionOptions { targetPipeline = PipelineIds[pipeline], keepOriginalShaderName = targetGraph == 0 && keepName,
                    presentation = new GraphPresentationOptions { autoLayout = autoLayout, addComments = addComments, useRegisters = useRegisters, longWireDistance = longWireDistance } };
                if (targetGraph == 1) { options.targetGraph = "ShaderGraph"; options.acceptStandardUnlitTarget = acceptStandardUnlitHost; nativeAnalysis = ShaderGraphNativePlanner.Analyze(source,inputPath,options); analysis = new ShaderConversionAnalysis { report = nativeAnalysis.report }; }
                else { analysis = ShaderConversionEngine.Analyze(source, inputPath, options); targetAnalyses = ShaderConversionEngine.AnalyzeTargets(source, inputPath, options); }
                conversionTab = 1; scroll = Vector2.zero;
            }
            catch (Exception e) { error = e.Message; }
        }

        private void DrawTargets()
        {
            if (targetAnalyses == null) return;
            showTargets = EditorGUILayout.Foldout(showTargets, CHToolLanguage.Text("Built-in / URP / HDRP 转换检查"), true);
            if (!showTargets) return;
            foreach (var target in targetAnalyses)
            {
                var r = target.report;
                string state = r.existingAseGraph ? CHToolLanguage.Text("已有 ASE 图，需在目标管线迁移") : r.CanGenerate ? CHToolLanguage.Text("分析通过，尚未生成验证") : CHToolLanguage.Text("需适配 ") + r.blockers.Count + CHToolLanguage.Text(" 项");
                EditorGUILayout.LabelField(r.pipeline, state);
            }
            EditorGUILayout.HelpBox(CHToolLanguage.Text("切换上方目标管线可查看具体阻塞并生成。实际生成需要当前 Unity 项目启用该管线，以及可用的 ASE 模板。"), MessageType.None);
        }

        private void DrawKnowledge()
        {
            var knowledge = analysis.knowledge;
            if (knowledge == null) return;
            showKnowledge = EditorGUILayout.Foldout(showKnowledge, CHToolLanguage.Text("转换规则与已记录的语义（") + knowledge.rules.Count + "）", true);
            if (!showKnowledge) return;
            EditorGUILayout.LabelField(CHToolLanguage.Text("规则库版本"), knowledge.libraryVersion);
            if(knowledge.sourceGraph!=null)
            {
                var sg=knowledge.sourceGraph;
                EditorGUILayout.HelpBox("Shader Graph · "+sg.format+" · "+sg.sourcePipeline+" / "+sg.target+CHToolLanguage.Text("\n节点 ")+sg.nodeCount+CHToolLanguage.Text("，连线 ")+sg.edgeCount+CHToolLanguage.Text("，属性 ")+sg.properties.Count+CHToolLanguage.Text("，关键词 ")+sg.keywordCount+CHToolLanguage.Text("。结构分析不等于 ASE 转换完成。"),MessageType.Info);
                foreach(var b in sg.blocks)EditorGUILayout.LabelField((b.connected?CHToolLanguage.Text("已连接 · "):CHToolLanguage.Text("默认值 · "))+b.descriptor);
                foreach(var dependency in sg.dependencies)EditorGUILayout.HelpBox(dependency,MessageType.None);
            }
            if (knowledge.materialCategories.Count > 0)
            {
                var catalog = ShaderRuleLibrary.Catalog();
                EditorGUILayout.LabelField(CHToolLanguage.Text("材质与动效分类线索"), string.Join(" / ", knowledge.materialCategories.ConvertAll(id => {
                    var category = catalog.categories.Find(c => c.id == id); return category == null ? id : category.title;
                }).ToArray()));
            }
            foreach(var character in knowledge.characterMaterials)
            {
                EditorGUILayout.LabelField(character.title + CHToolLanguage.Text(" · 人物材质分析，尚未生成验证"), EditorStyles.boldLabel);
                EditorGUILayout.HelpBox(CHToolLanguage.Text("识别线索：") + string.Join("、", character.matchedSignals.ToArray()) + CHToolLanguage.Text("\n待核对：") + string.Join("；", character.requiredReview.ToArray()), MessageType.None);
            }
            if(knowledge.characterMaterials.Count>0 && GUILayout.Button(CHToolLanguage.Text("在 ASE 着色器库查看人物分类与适配要求"))) ShaderLibraryWindow.OpenCategory(knowledge.characterMaterials[0].profileId);
            EditorGUILayout.LabelField(CHToolLanguage.Text("静态成本线索（未测 GPU）"), CHToolLanguage.Text("采样位置 ") + knowledge.performance.directTextureSampleSites + CHToolLanguage.Text(" / 循环 ") + knowledge.performance.loopSites + CHToolLanguage.Text(" / 显式 Pass ") + knowledge.performance.explicitPasses);
            foreach (string observation in knowledge.performance.observations) EditorGUILayout.HelpBox(observation, MessageType.None);
            if (!string.IsNullOrEmpty(knowledge.referenceFile))
                EditorGUILayout.HelpBox(knowledge.referenceFile + "：" + knowledge.referenceNotes, MessageType.None);
            if (knowledge.graph.present)
            {
                EditorGUILayout.LabelField(CHToolLanguage.Text("原图版本 / 节点 / 连线"), knowledge.graph.version + " / " + knowledge.graph.nodeCount + " / " + knowledge.graph.wireCount);
                foreach (string guid in knowledge.graph.functionGuids) EditorGUILayout.LabelField(CHToolLanguage.Text("依赖 Function GUID"), guid);
            }
            foreach (var rule in knowledge.rules)
            {
                string state = rule.implementation == "NativePlanner" ? CHToolLanguage.Text("原生计划规则") : rule.implementation == "AseMigration" ? CHToolLanguage.Text("ASE 迁移规则") : rule.implementation == "AnalysisRule" ? CHToolLanguage.Text("分析规则") : CHToolLanguage.Text("已记录，仍需适配验证");
                EditorGUILayout.LabelField(rule.title + " · " + state, EditorStyles.boldLabel);
                EditorGUILayout.HelpBox(rule.recipe + CHToolLanguage.Text("\n保留：") + string.Join("；", rule.preserve.ToArray()), MessageType.None);
            }
            foreach (string note in knowledge.notes) EditorGUILayout.HelpBox(note, MessageType.None);
        }

        private void Generate()
        {
            Analyze();
            if (analysis == null || !analysis.report.CanGenerate) return;
            generationAttempted = true;
            if (targetGraph == 1) ShaderGraphEditorBridge.Generate(nativeAnalysis.plan,outputPath,analysis.report);
            else AseEditorBridge.Generate(analysis.plan, outputPath, analysis.report);
            if (!string.IsNullOrEmpty(analysis.report.outputPath)) EditorGUIUtility.PingObject(AssetDatabase.LoadAssetAtPath<Shader>(analysis.report.outputPath));
        }

        private void DrawInput()
        {
            if (inputShader == null) inputShader = LoadInputShader();
            EditorGUI.BeginChangeCheck();
            var chosen = (Shader)EditorGUILayout.ObjectField(new GUIContent(CHToolLanguage.Text("输入 Shader"), CHToolLanguage.Text("可从 Project 窗口拖入 .shader 文件")), inputShader, typeof(Shader), false);
            if (EditorGUI.EndChangeCheck())
            {
                string path = chosen == null ? "" : AssetDatabase.GetAssetPath(chosen);
                if (chosen == null || IsShaderFile(path)) SetInput(path);
                else error = CHToolLanguage.Text("请选择包含源码的 .shader 文件。Unity 内置 Shader 不能作为文件输入。");
            }
            EditorGUILayout.BeginHorizontal();
            Rect pathArea = EditorGUILayout.GetControlRect();
            inputPathArea = new Rect(GUIUtility.GUIToScreenPoint(pathArea.position) - position.position, pathArea.size);
            HandleDrop(pathArea);
            string edited = EditorGUI.TextField(pathArea, CHToolLanguage.Text("文件路径"), inputPath);
            if (edited != inputPath) SetInput(edited);
            if (GUILayout.Button(CHToolLanguage.Text("浏览"), GUILayout.Width(60)))
            {
                string path = EditorUtility.OpenFilePanelWithFilters(CHToolLanguage.Text("选择 Shader 或 Shader Graph"), IsInputDirectory(inputPath) ? SourceDiskPath(inputPath) : Application.dataPath, new[]{"Shader / Shader Graph","shader,shadergraph,shadersubgraph"});
                if (!string.IsNullOrEmpty(path)) SetInput(path);
            }
            if (GUILayout.Button(CHToolLanguage.Pick("目录", "Folder"), GUILayout.Width(60)))
            {
                string path = EditorUtility.OpenFolderPanel(CHToolLanguage.Pick("选择目录", "Select folder"), IsInputDirectory(inputPath) ? SourceDiskPath(inputPath) : Application.dataPath, "");
                if (!string.IsNullOrEmpty(path)) SetInput(path);
            }
            EditorGUILayout.EndHorizontal();
            Rect dropArea = GUILayoutUtility.GetRect(0, 38, GUILayout.ExpandWidth(true));
            GUI.Box(dropArea, CHToolLanguage.Pick("拖入 Shader 文件或目录（支持 Unity Project 与系统文件夹）", "Drop a Shader file or folder (Unity Project or system folder)"), EditorStyles.helpBox);
            HandleDrop(dropArea);
            if (IsInputDirectory(inputPath)) EditorGUILayout.HelpBox(CHToolLanguage.Pick("已选择目录。可点击“浏览”从此目录选择文件后转换。", "Folder selected. Click Browse to choose a file in this folder for conversion."), MessageType.None);
        }

        private void HandleDrop(Rect area)
        {
            Event evt = Event.current;
            if ((evt.type != EventType.DragUpdated && evt.type != EventType.DragPerform) || !area.Contains(evt.mousePosition)) return;
            string path;
            bool accepted = TryGetDraggedShader(out path);
            DragAndDrop.visualMode = accepted ? DragAndDropVisualMode.Copy : DragAndDropVisualMode.Rejected;
            if (accepted && evt.type == EventType.DragPerform)
            {
                DragAndDrop.AcceptDrag();
                SetInput(path);
                GUI.FocusControl(null);
                Repaint();
            }
            evt.Use();
        }

        private void HandleOutputDirectoryDrop(Rect area)
        {
            Event evt = Event.current;
            if ((evt.type != EventType.DragUpdated && evt.type != EventType.DragPerform) || !area.Contains(evt.mousePosition)) return;
            string path, directory;
            bool accepted = TryGetDraggedShader(out path) && IsInputDirectory(path) && TryOutputDirectory(path, out directory);
            DragAndDrop.visualMode = accepted ? DragAndDropVisualMode.Copy : DragAndDropVisualMode.Rejected;
            if (evt.type == EventType.DragPerform)
            {
                if (accepted && TryOutputDirectory(path, out directory))
                {
                    DragAndDrop.AcceptDrag(); outputDirectory = directory;
                    string extension = targetGraph == 0 ? ".shader" : ".shadergraph";
                    string filename = Path.GetFileName(outputPath);
                    if (string.IsNullOrEmpty(filename) || Path.GetExtension(filename) != extension) filename = "Converted" + (targetGraph == 0 ? "_ASE" : "_SG") + extension;
                    outputPath = AssetDatabase.GenerateUniqueAssetPath(directory + "/" + filename);
                    error = ""; GUI.FocusControl(null); Repaint();
                }
                else error = CHToolLanguage.Pick("输出目录请选择当前项目 Assets 内的文件夹。", "Choose an output folder under this project's Assets directory.");
            }
            evt.Use();
        }
        private static bool TryOutputDirectory(string path, out string directory)
        {
            directory = "";
            try
            {
                string disk = SourceDiskPath(path).Replace('\\', '/').TrimEnd('/');
                string assets = Application.dataPath.Replace('\\', '/').TrimEnd('/');
                if (disk.Equals(assets, StringComparison.OrdinalIgnoreCase)) directory = "Assets";
                else if (disk.StartsWith(assets + "/", StringComparison.OrdinalIgnoreCase)) directory = "Assets/" + disk.Substring(assets.Length + 1);
                return directory.Length > 0 && AssetDatabase.IsValidFolder(directory);
            }
            catch (Exception) { return false; }
        }
        private void RememberOutputDirectory()
        {
            string directory;
            try { if (TryOutputDirectory(Path.GetDirectoryName(outputPath), out directory)) outputDirectory = directory; }
            catch (Exception) { /* Allow incomplete path edits. */ }
        }
        private void SuggestOutputPath(string source)
        {
            string directory = outputDirectory;
            if (string.IsNullOrEmpty(directory) || !AssetDatabase.IsValidFolder(directory))
                directory = source != null && source.StartsWith("Assets/", StringComparison.Ordinal) ? Path.GetDirectoryName(source).Replace('\\', '/') : "Assets";
            string filename = source == null ? "Converted" : Path.GetFileNameWithoutExtension(source);
            outputPath = AssetDatabase.GenerateUniqueAssetPath(directory + "/" + filename + (targetGraph == 0 ? "_ASE.shader" : "_SG.shadergraph"));
        }

        private static bool TryGetDraggedShader(out string path)
        {
            path = "";
            if (DragAndDrop.paths.Length > 1 || DragAndDrop.objectReferences.Length > 1) return false;
            if (DragAndDrop.paths.Length == 1)
            {
                path = DragAndDrop.paths[0];
            }
            else
            {
                if (DragAndDrop.objectReferences.Length != 1) return false;
                path = AssetDatabase.GetAssetPath(DragAndDrop.objectReferences[0]);
            }
            return IsShaderFile(path) || IsInputDirectory(path);
        }

        private static bool IsInputDirectory(string path)
        {
            try { return !string.IsNullOrWhiteSpace(path) && Directory.Exists(SourceDiskPath(path)); }
            catch (Exception) { return false; }
        }

        private static bool IsShaderFile(string path)
        {
            if (string.IsNullOrWhiteSpace(path) || !new[]{".shader",".shadergraph",".shadersubgraph"}.Contains(Path.GetExtension(path).ToLowerInvariant())) return false;
            try { return File.Exists(SourceDiskPath(path)); }
            catch (Exception) { return false; }
        }

        private static string SourceDiskPath(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentException(CHToolLanguage.Text("请先拖入或选择一个 .shader 文件。"));
            string normalized = path.Replace('\\', '/');
            if (normalized.StartsWith("Packages/", StringComparison.Ordinal))
            {
                var package = UnityEditor.PackageManager.PackageInfo.FindForAssetPath(normalized);
                if (package != null)
                {
                    string root = "Packages/" + package.name;
                    if (normalized.TrimEnd('/') == root) return package.resolvedPath;
                    if (normalized.StartsWith(root+"/",StringComparison.Ordinal)) return Path.Combine(package.resolvedPath, normalized.Substring(root.Length+1));
                }
            }
            return Path.GetFullPath(path);
        }

        private void SetInput(string path)
        {
            string normalized = (path ?? "").Replace('\\', '/');
            string assets = Application.dataPath.Replace('\\', '/') + "/";
            // Unity may report a package alias for a physical Assets folder when
            // a local package contains the project. Prefer the current project's
            // canonical Assets path whenever both references resolve there.
            try
            {
                string disk = SourceDiskPath(normalized).Replace('\\','/').TrimEnd('/');
                if (disk.Equals(assets.TrimEnd('/'),StringComparison.OrdinalIgnoreCase)) normalized = "Assets";
                else if (disk.StartsWith(assets,StringComparison.OrdinalIgnoreCase)) normalized = "Assets/" + disk.Substring(assets.Length);
            }
            catch (Exception) { /* Keep incomplete text editable. */ }
            if (normalized == inputPath) return;
            inputPath = normalized;
            inputShader = LoadInputShader();
            ClearAnalysis();
            if (!string.IsNullOrWhiteSpace(inputPath) && IsShaderFile(inputPath))
            {
                SuggestOutputPath(inputPath);
            }
        }

        private Shader LoadInputShader()
        {
            return inputPath.StartsWith("Assets/", StringComparison.Ordinal) || inputPath.StartsWith("Packages/", StringComparison.Ordinal)
                ? AssetDatabase.LoadAssetAtPath<Shader>(inputPath) : null;
        }

        private void ClearAnalysis() { analysis = null; nativeAnalysis = null; targetAnalyses = null; error = ""; generationAttempted = false; showOriginalMessages = false; }

        private static void DrawMessages(List<string> messages, string title, MessageType severity)
        {
            if (messages.Count == 0) return;
            EditorGUILayout.Space();
            EditorGUILayout.LabelField(title + "（" + messages.Count + "）", EditorStyles.boldLabel);
            foreach (string message in messages) EditorGUILayout.HelpBox(ShaderConverterMessages.Explain(message), severity);
        }

        private static void DrawOriginalMessages(List<string> messages)
        {
            foreach (string message in messages)
                EditorGUILayout.SelectableLabel(message, EditorStyles.wordWrappedLabel, GUILayout.MinHeight(EditorStyles.wordWrappedLabel.CalcHeight(new GUIContent(message), Mathf.Max(200, EditorGUIUtility.currentViewWidth - 48))));
        }

        private void UseSelection()
        {
            string path = AssetDatabase.GetAssetPath(Selection.activeObject);
            if (!IsShaderFile(path)) return;
            SetInput(path);
        }
    }
}
