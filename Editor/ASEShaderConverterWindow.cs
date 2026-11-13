using System;
using System.Linq;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    public sealed class ASEShaderConverterWindow : EditorWindow
    {
        [SerializeField] private string inputPath = "", outputPath = "Assets/Converted_ASE.shader";
        [SerializeField] private int pipeline;
        [SerializeField] private int targetGraph;
        [SerializeField] private bool acceptStandardTarget;
        private ShaderGraphNativeAnalysis nativeAnalysis;
        private ShaderGraphEnvironmentInfo nativeEnvironment;
        [SerializeField] private bool keepName;
        [SerializeField] private bool advanced, autoLayout = true, addComments = true, useRegisters = true;
        [SerializeField] private float longWireDistance = 1800;
        private Vector2 scroll;
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

        private void OnEnable() { titleContent = new GUIContent(CHToolLanguage.Text("Shader转换器")); }

        [MenuItem("Tools/Shader转换器/打开转换器")]
        public static void Open()
        {
            var window = GetWindow<ASEShaderConverterWindow>(CHToolLanguage.Text("Shader转换器"));
            window.minSize = new Vector2(580, 440);
            window.UseSelection(); window.Show();
        }

        [MenuItem("Assets/Shader转换器/分析并转换", true)]
        private static bool CanOpen() { return IsShaderFile(AssetDatabase.GetAssetPath(Selection.activeObject)); }
        [MenuItem("Assets/Shader转换器/分析并转换")]
        private static void OpenSelected() { Open(); }

        private void OnGUI()
        {
            titleContent = new GUIContent(CHToolLanguage.Text("Shader转换器"));
            if (GUILayout.Button(CHToolLanguage.Pick("工具集设置", "Tool settings"))) CHToolLanguage.OpenSettings();
            scroll = EditorGUILayout.BeginScrollView(scroll);
            if (GUILayout.Button(CHToolLanguage.Text("插件更新（检查版本与 Git 升级）"))) ShaderPackageUpdateWindow.Open();
            if (GUILayout.Button(CHToolLanguage.Text("ASE 着色器库（分类、搜索与一键安装）"))) ShaderLibraryWindow.Open();
            EditorGUILayout.HelpBox(CHToolLanguage.Text("统一入口：手写 Shader → ASE / Shader Graph；Shader Graph → ASE、ASE → Shader Graph 先分析阻塞，再由 Agent 提交审查后的原生计划。"), MessageType.Info);
            DrawInput();
            EditorGUI.BeginChangeCheck();
            targetGraph = EditorGUILayout.Popup(CHToolLanguage.Text("输出图格式"),targetGraph,new[]{"ASE",CHToolLanguage.Text("Shader Graph（URP 原生子集）")});
            if (EditorGUI.EndChangeCheck()) { ClearAnalysis(); outputPath = AssetDatabase.GenerateUniqueAssetPath("Assets/Converted"+(targetGraph == 0 ? "_ASE.shader" : "_SG.shadergraph")); }
            if (targetGraph == 1)
            {
                EditorGUI.BeginChangeCheck();
                acceptStandardTarget = EditorGUILayout.ToggleLeft(CHToolLanguage.Text("使用标准 URP Unlit 宿主（雾 / AO / Decal / 附加 Pass；不代表原宿主等价）"),acceptStandardTarget);
                if (EditorGUI.EndChangeCheck()) ClearAnalysis();
                EditorGUILayout.HelpBox(CHToolLanguage.Text("当前适配：Unity 2022.3 + Shader Graph / URP 14.0.8。手写输入要求 Alpha 恒为 1；数学、Float/Range/Vector 参数、2D 纹理采样及直接 UV 插值可转换。Color 属性、复杂顶点与渲染状态仍需适配。"),MessageType.None);
            }
            EditorGUILayout.BeginHorizontal();
            outputPath = EditorGUILayout.TextField(CHToolLanguage.Text("输出 Shader"), outputPath);
            if (GUILayout.Button(CHToolLanguage.Text("选择"), GUILayout.Width(60)))
            {
                string chosen = EditorUtility.SaveFilePanelInProject(CHToolLanguage.Text("保存转换图"), targetGraph == 0 ? "Converted_ASE" : "Converted_SG", targetGraph == 0 ? "shader" : "shadergraph", CHToolLanguage.Text("选择新的输出文件"));
                if (!string.IsNullOrEmpty(chosen)) outputPath = chosen;
            }
            EditorGUILayout.EndHorizontal();
            EditorGUI.BeginChangeCheck();
            pipeline = EditorGUILayout.Popup(CHToolLanguage.Text("目标管线"), pipeline, CHToolLanguage.Text(PipelineNames));
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
            using (new EditorGUI.DisabledScope(string.IsNullOrWhiteSpace(inputPath)))
            {
                if (GUILayout.Button(CHToolLanguage.Text("分析"))) Analyze();
                using (new EditorGUI.DisabledScope(analysis != null && (analysis.report.status == "NeedsAgent" || analysis.report.existingAseGraph)))
                {
                    if (GUILayout.Button(CHToolLanguage.Text("生成并验证"))) Generate();
                }
            }
            if (GUILayout.Button(CHToolLanguage.Text("检查环境"))) { if(targetGraph == 0) environment = AseEditorBridge.Probe(); else nativeEnvironment = ShaderGraphEditorBridge.Probe(); }
            if (GUILayout.Button(CHToolLanguage.Text("使用选中 Shader"))) UseSelection();
            EditorGUILayout.EndHorizontal();
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
            if (!string.IsNullOrEmpty(error)) EditorGUILayout.HelpBox(error, MessageType.Error);
            if (targetGraph == 1 && nativeEnvironment != null) { EditorGUILayout.LabelField("Unity / Shader Graph / URP",nativeEnvironment.unityVersion+" / "+nativeEnvironment.shaderGraphVersion+" / "+nativeEnvironment.urpVersion); DrawMessages(nativeEnvironment.errors,CHToolLanguage.Text("环境问题"),MessageType.Error); }
            if (targetGraph == 0 && environment != null)
            {
                EditorGUILayout.LabelField("Unity / ASE", environment.unityVersion + " / " + environment.aseVersion);
                EditorGUILayout.LabelField(CHToolLanguage.Text("当前管线"), environment.activePipeline);
                DrawMessages(environment.errors, CHToolLanguage.Text("环境问题"), MessageType.Error);
                foreach (var template in environment.templates) EditorGUILayout.LabelField((template.ready ? CHToolLanguage.Text("可用：") : CHToolLanguage.Text("需导入：")) + template.name);
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
            EditorGUILayout.EndScrollView();
        }

        private void Analyze()
        {
            ClearAnalysis();
            try
            {
                string source = File.ReadAllText(SourceDiskPath(inputPath));
                var options = new ShaderConversionOptions { targetPipeline = PipelineIds[pipeline], keepOriginalShaderName = targetGraph == 0 && keepName,
                    presentation = new GraphPresentationOptions { autoLayout = autoLayout, addComments = addComments, useRegisters = useRegisters, longWireDistance = longWireDistance } };
                if (targetGraph == 1) { options.targetGraph = "ShaderGraph"; options.acceptStandardUrpUnlitTarget = acceptStandardTarget; nativeAnalysis = ShaderGraphNativePlanner.Analyze(source,inputPath,options); analysis = new ShaderConversionAnalysis { report = nativeAnalysis.report }; }
                else { analysis = ShaderConversionEngine.Analyze(source, inputPath, options); targetAnalyses = ShaderConversionEngine.AnalyzeTargets(source, inputPath, options); }
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
            string edited = EditorGUILayout.TextField(CHToolLanguage.Text("文件路径"), inputPath);
            if (edited != inputPath) SetInput(edited);
            if (GUILayout.Button(CHToolLanguage.Text("浏览"), GUILayout.Width(60)))
            {
                string path = EditorUtility.OpenFilePanelWithFilters(CHToolLanguage.Text("选择 Shader 或 Shader Graph"), Application.dataPath, new[]{"Shader / Shader Graph","shader,shadergraph,shadersubgraph"});
                if (!string.IsNullOrEmpty(path)) SetInput(path);
            }
            EditorGUILayout.EndHorizontal();
            Rect dropArea = GUILayoutUtility.GetRect(0, 38, GUILayout.ExpandWidth(true));
            GUI.Box(dropArea, CHToolLanguage.Text("拖入 .shader / .shadergraph / .shadersubgraph（支持系统文件夹）"), EditorStyles.helpBox);
            HandleDrop(dropArea);
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

        private static bool TryGetDraggedShader(out string path)
        {
            path = "";
            if (DragAndDrop.objectReferences.Length > 0)
            {
                if (DragAndDrop.objectReferences.Length != 1) return false;
                path = AssetDatabase.GetAssetPath(DragAndDrop.objectReferences[0]);
            }
            else
            {
                if (DragAndDrop.paths.Length != 1) return false;
                path = DragAndDrop.paths[0];
            }
            return IsShaderFile(path);
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
                if (package != null) return Path.Combine(package.resolvedPath, normalized.Substring(("Packages/" + package.name + "/").Length));
            }
            return Path.GetFullPath(path);
        }

        private void SetInput(string path)
        {
            string normalized = path.Replace('\\', '/');
            string assets = Application.dataPath.Replace('\\', '/') + "/";
            if (normalized.StartsWith(assets, StringComparison.OrdinalIgnoreCase)) normalized = "Assets/" + normalized.Substring(assets.Length);
            if (normalized == inputPath) return;
            inputPath = normalized;
            inputShader = LoadInputShader();
            ClearAnalysis();
            if (!string.IsNullOrWhiteSpace(inputPath) && IsShaderFile(inputPath))
            {
                string directory = inputPath.StartsWith("Assets/", StringComparison.Ordinal) ? Path.GetDirectoryName(inputPath) : "Assets";
                outputPath = AssetDatabase.GenerateUniqueAssetPath(Path.Combine(directory, Path.GetFileNameWithoutExtension(inputPath) + (targetGraph == 0 ? "_ASE.shader" : "_SG.shadergraph")).Replace('\\', '/'));
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
