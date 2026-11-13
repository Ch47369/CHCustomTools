using System;
using UnityEditor;

namespace ASEShaderConverter.Editor
{
    // Presentation only: the analysis report and generation checks keep their original diagnostics.
    internal static class ShaderConverterMessages
    {
        public static MessageType Severity(ShaderConversionReport report)
        {
            if (report.status == "GenerationFailed" || report.status == "ValidationFailed" || report.status == "Blocked") return MessageType.Error;
            return report.blockers.Count > 0 ? MessageType.Warning : MessageType.Info;
        }

        public static string Summary(ShaderConversionReport report)
        {
            string graph = report.targetGraph == "ShaderGraph" ? "Shader Graph" : "ASE";
            switch (report.status)
            {
                case "NeedsAgent": return CHToolLanguage.Text("需要适配：此 Shader 超出当前自动转换范围，共有 ") + report.blockers.Count + CHToolLanguage.Text(" 项阻塞。请复制或导出报告，交给 Agent 逐项适配节点与模板设置；适配完成前无法自动生成。");
                case "ExistingAseGraph": return CHToolLanguage.Text("此文件已经包含 ASE 图。请用已安装的 ASE 打开并迁移。");
                case "Generated": return report.visualComparisonPassed ? CHToolLanguage.Text("生成、")+graph+CHToolLanguage.Text(" 重载、Shader 编译及画面对比已通过。") : CHToolLanguage.Text("生成、")+graph+CHToolLanguage.Text(" 重载和 Shader 编译已通过。画面对比尚未验证，请在目标场景比较原、新材质。");
                case "GenerationFailed": return CHToolLanguage.Text("生成失败。请检查下方原因，输出路径中可能保留了用于诊断的文件。");
                case "ValidationFailed": return CHToolLanguage.Text("验证未通过。已保存的图还不能视为成功转换，请检查 ")+graph+CHToolLanguage.Text(" 重载与 Shader 编译结果。");
                case "Blocked": return CHToolLanguage.Text("生成已阻塞。请按下方原因检查环境、模板和输出路径，再重新分析。");
                case "Planned": return CHToolLanguage.Text("分析通过，可以生成。")+graph+CHToolLanguage.Text(" 保存重载与 Shader 编译尚未验证，请点击“生成并验证”。");
                default: return CHToolLanguage.Text("当前状态：") + report.status;
            }
        }

        // Keep property names, state values, and other diagnostic evidence visible in the UI.
        private static readonly string[,] Prefixes =
        {
            { "Property attributes need explicit ASE mapping: ", "属性设置尚未适配（需保留属性名及特性）：" },
            { "Render state needs ASE mapping: ", "渲染状态尚未适配（需设置对应的 ASE 模板选项）：" },
            { "Texture kind requires an agent sampler plan: ", "此纹理类型需要专门的属性和采样节点：" },
            { "Tag needs explicit template mapping: ", "标签尚未适配（需保留对应的模板行为）：" },
            { "Helper/overloaded function needs explicit semantic mapping: ", "自定义函数需要逐项转换为节点：" },
            { "Recursive or excessive helper expansion: ", "辅助函数递归或展开过多，需要单独适配：" },
            { "Include needs explicit dependency mapping: ", "引用文件中的依赖需要逐项适配：" },
            { "Pragma requires explicit ASE mapping: ", "编译指令尚未适配：" },
            { "Preprocessor directive requires explicit mapping: ", "预处理指令尚未适配：" },
            { "Function requires a native node mapping or a self-contained Custom Expression with explicit inputs: ", "函数需要原生节点映射，或明确输入的 Custom Expression：" },
            { "Mutable or unrecognized fragment statement: ", "赋值或语句超出自动转换范围，需要明确的节点连接：" },
            { "Vertex modifications/varyings need explicit ASE mapping: ", "顶点修改或插值数据需要适配：" },
            { "Unresolved identifier: ", "变量尚未解析，需要明确来源：" },
            { "Target pipeline must match this project's active pipeline: ", "请选择与当前项目一致的目标管线：" },
            { "Output already exists. Choose a new .shader path: ", "输出文件已存在，请选择新的 .shader 路径：" },
            { "ASE type is not installed/loaded: ", "ASE 类型尚未加载，请检查 ASE 安装及 Unity Console 编译错误：" },
            { "The target ASE template is missing, a placeholder, or belongs to another pipeline. Import ASE's matching SRP template package first: ", "目标 ASE 模板缺失或管线不匹配，请先导入对应管线与版本的模板包：" }
        };

        public static string Explain(string message)
        {
            if (!CHToolLanguage.IsChinese) return message;
            for (int i = 0; i < Prefixes.GetLength(0); i++)
                if (message.StartsWith(Prefixes[i, 0], StringComparison.Ordinal)) return Prefixes[i, 1] + message.Substring(Prefixes[i, 0].Length);
            switch (message)
            {
                case "Incomplete ASE graph metadata. Recover the original graph before migration; do not rebuild its generated HLSL.": return "ASE 图数据不完整。请先恢复完整源文件，再由 ASE 迁移；不能从生成代码伪造还原图。";
                case "Non-default shader target requires explicit template settings.": return "Shader 使用了较高的编译目标（#pragma target），需要适配对应的 ASE 模板设置。";
                case "Additional ShaderLab behavior requires an agent plan.": return "Shader 包含额外行为（如 Fallback、CustomEditor、Fog），需要审核并适配到 ASE 模板。";
                case "Preprocessor branches and macros require explicit agent mapping.": return "宏与条件编译分支需要逐项适配，才能保留所有分支行为。";
                case "Multiple or implicit passes require explicit agent mapping.": return "Shader 含多个 Pass 或隐式 Pass，需要逐项适配各 Pass 的节点和设置。";
                case "Multiple SubShaders require explicit agent mapping.": return "Shader 含多个 SubShader，需要逐项适配各自的行为。";
                case "Stencil/GrabPass/UsePass requires explicit ASE template settings.": return "Stencil、GrabPass 或 UsePass 需要适配对应的 ASE 模板设置。";
                case "Transparency/queue/alpha clipping needs explicit template options and Alpha output.": return "透明、渲染队列或 Alpha 裁剪需要适配模板选项及 Alpha 输出。";
                case "Shader variants or additional stages require explicit ASE mapping.": return "变体或额外的着色阶段需要适配到 ASE。";
                case "Fragment control flow or clip/discard requires an agent plan; preserve its side effects and inputs.": return "片元条件分支、循环或裁剪需要明确的节点计划，以保留相关输入与行为。";
                case "HDRP raw fragment output needs an agent plan that explicitly reviews template passes, exposure, fog, blending, and alpha behavior.": return "HDRP 片元输出需要审核模板 Pass、曝光、雾、混合与 Alpha，当前无法自动转换。";
                case "A plan is not a validated ASE shader. Generate and reload it in the target Unity/ASE environment, then compare rendering with the source.": return "分析只生成节点计划。生成后还需通过 ASE 重载、Unity 编译，并在目标场景比较画面。";
                case "Rendering equivalence has not been checked. Compare source and generated materials in the target pipeline.": return "画面等价性尚未验证，请在目标管线中对比原、新材质。";
                case "ASE 1.9.9.13 serializes the empty 2DArray default as the token white. No default array asset is assigned; the source default token remains recorded in the plan. Validate unassigned textures separately.": return "ASE 会把空的 2DArray 默认值写成 white 标记，未绑定默认数组资源；原默认值保留在计划中。请另行检查未赋纹理时的表现。";
                case "This UI adapter is restricted to the reviewed source signature. It uses the converter's hard-clip/straight-alpha UI template; ASE's default UI template has different blending and clipping.": return "此 UI 转换仅支持已审核的源码版本。使用插件自带的模板保留原有裁剪和透明混合；修改源码后可能需要重新适配。";
                case "This Normal360 adapter is restricted to the reviewed source signature and requires the converter's two-sided fog template.": return "此 Normal360 转换仅支持已审核的源码版本，使用插件自带模板保留顶点纹理缩放偏移、双面显示和 Unity 雾效。";
                case "The input already contains an ASE graph. Open/migrate it with the installed ASE; do not reconstruct it from generated HLSL.": return "输入已有 ASE 图，请使用 ASE 打开并迁移。";
                default: return message;
            }
        }
    }
}
