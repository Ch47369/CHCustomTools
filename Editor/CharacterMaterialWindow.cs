using System.Linq;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    // Compatibility entry for callers and saved layouts; the library owns character browsing.
    public sealed class CharacterMaterialWindow : EditorWindow
    {
        public static void Open(){ShaderLibraryWindow.OpenCategory("Skin");}
        void OnEnable(){EditorApplication.update+=Redirect;}
        void OnDisable(){EditorApplication.update-=Redirect;}
        void Redirect(){if(this==null)return;Open();Close();}
    }

    internal sealed class CharacterMaterialPanel
    {
        public bool Expanded;
        string context="",environmentResult="",descriptionResult="";
        readonly System.Collections.Generic.List<CharacterMaterialProfile> profiles=CharacterMaterialLibrary.Profiles();
        public void Draw(string category,string target)
        {
            var profile=profiles.FirstOrDefault(p=>p.id==category);
            if(profile==null)return;
            if(context!=category+target){context=category+target;environmentResult=descriptionResult="";}
            Expanded=EditorGUILayout.Foldout(Expanded,CHToolLanguage.Text("材质说明与适配要求 · ")+profile.title,true);
            if(!Expanded)return;
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            EditorGUILayout.HelpBox(CHToolLanguage.Text("以下是完整人物材质的输入和验证要求。分类中的基础示例与已适配图以各自功能契约为准。\n")+profile.qualityTarget,MessageType.Info);
            EditorGUILayout.LabelField(CHToolLanguage.Text("网格与宿主"),EditorStyles.boldLabel);EditorGUILayout.HelpBox(profile.geometry,MessageType.None);
            EditorGUILayout.LabelField(CHToolLanguage.Text("输入资源与颜色空间"),EditorStyles.boldLabel);
            foreach(var input in profile.inputs)EditorGUILayout.HelpBox(input.name+" · "+input.colorSpace+"\n"+input.usage,MessageType.None);
            var requirement=profile.pipelines.FirstOrDefault(p=>p.pipeline==target);
            if(requirement!=null)
            {
                EditorGUILayout.LabelField(target+CHToolLanguage.Text(" · 专用模型要求"),EditorStyles.boldLabel);EditorGUILayout.HelpBox(requirement.requirements,MessageType.Warning);
                if(GUILayout.Button(CHToolLanguage.Text("检查当前项目环境与参考模板端口")))InspectTarget(target,requirement.referenceTemplateGuid);
            }
            if(environmentResult.Length>0)EditorGUILayout.HelpBox(environmentResult,MessageType.Info);
            if(descriptionResult.Length>0)EditorGUILayout.HelpBox(descriptionResult,MessageType.None);
            DrawList(CHToolLanguage.Text("必须保留的语义"),profile.preserve.ToArray());DrawList(CHToolLanguage.Text("实际验证要求"),profile.validation.ToArray());
            DrawList(CHToolLanguage.Text("成本线索（无 GPU 基准）"),profile.costs.ToArray());DrawList(CHToolLanguage.Text("研究来源"),profile.sources.ToArray());
            EditorGUILayout.EndVertical();
        }
        static void DrawList(string title,string[] values)
        {
            EditorGUILayout.LabelField(title,EditorStyles.boldLabel);foreach(string value in values)EditorGUILayout.HelpBox(value,MessageType.None);
        }
        void InspectTarget(string target,string guid)
        {
            descriptionResult="";var probe=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});
            if(!probe.success){environmentResult=CHToolLanguage.Text("环境检查失败：")+probe.error;return;}
            environmentResult="Unity "+probe.environment.unityVersion+" / ASE "+probe.environment.aseVersion+" / "+probe.environment.activePipeline;
            if(probe.environment.activePipeline!=target){environmentResult+=CHToolLanguage.Text("\n当前项目管线与所选目标不同，请在目标管线项目中核对。");return;}
            if(string.IsNullOrEmpty(guid)){environmentResult+=CHToolLanguage.Text("\n本档案未登记该管线的已核对参考模板，需要专门适配。");return;}
            if(!probe.environment.templates.Any(t=>t.guid==guid&&t.ready)){environmentResult+=CHToolLanguage.Text("\n当前 ASE 未激活参考模板：")+guid;return;}
            var description=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="describe",templateGuid=guid});
            if(!description.success){descriptionResult=CHToolLanguage.Text("模板描述失败：")+description.error;return;}
            descriptionResult=CHToolLanguage.Text("参考模板端口已读取；尚未配置或生成图。\n")+JsonUtility.ToJson(description.description,true);
        }
    }
}
