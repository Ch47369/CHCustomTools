using System;
using System.Linq;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    public sealed class ShaderLibraryWindow : EditorWindow
    {
        ShaderLibraryCatalog catalog;
        string search="", activePipeline="", categoryId="", researchCategoryId="", loadError="";
        int pipeline,device,tier,grouping,tab,scope,showcasePreset;
        Vector2 scroll;
        bool overview;
        HashSet<string> completeFamilies,mappedFamilies;
        ShaderLibraryCategorySummary[] assetCategories,researchCategories,coverageCategories;
        readonly Dictionary<string,bool> expanded=new Dictionary<string,bool>();
        readonly CharacterMaterialPanel character=new CharacterMaterialPanel();
        readonly string[] pipelines={"全部管线","BuiltIn","URP","HDRP"},devices={"全部设备","Mobile","Pad","PC"},deviceLabels={"全部设备","移动端 / 手机","Pad / 平板","PC / 电脑"},tiers={"全部复杂度","Low","Medium","High","Unrated"},tierLabels={"全部复杂度","低复杂度","中复杂度","高复杂度","未分级"};
        [MenuItem("Tools/Shader/ASE 着色器库")]
        public static void Open(){var window=GetWindow<ShaderLibraryWindow>(CHToolLanguage.Text("ASE 着色器库"));window.minSize=new Vector2(680,520);window.Show();}
        public static void OpenCategory(string id)
        {
            Open();var window=GetWindow<ShaderLibraryWindow>();window.ResetFilters();window.categoryId=id;window.character.Expanded=true;
        }
        void OnEnable(){Reload();}
        void Reload()
        {
            try
            {
                catalog=ShaderLibraryAssets.Load();loadError="";
                activePipeline=AseEditorBridge.Probe().activePipeline;
                completeFamilies=new HashSet<string>(catalog.entries.GroupBy(ShaderLibraryQuery.Family).Where(ShaderLibraryQuery.HasThreeArtifacts).Select(g=>g.Key));
                mappedFamilies=new HashSet<string>(catalog.entries.GroupBy(ShaderLibraryQuery.Family).Where(g=>ShaderLibraryQuery.HasThreeMappedTargets(catalog.familyContracts.FirstOrDefault(c=>c.familyId==g.Key),g)).Select(g=>g.Key));
                assetCategories=ShaderLibraryQuery.Categories(catalog);coverageCategories=ShaderLibraryQuery.Categories(catalog,true);
                researchCategories=coverageCategories.Where(c=>c.researchSources>0).ToArray();
                pipeline=Math.Max(0,Array.IndexOf(pipelines,activePipeline));
            }catch(Exception e){catalog=null;loadError=e.Message;Debug.LogException(e);}
        }
        void ResetFilters()
        {
            search="";categoryId="";researchCategoryId="";device=tier=scope=grouping=tab=0;
            pipeline=Math.Max(0,Array.IndexOf(pipelines,activePipeline));scroll=Vector2.zero;
        }
        void OnInspectorUpdate(){if(ShaderLibraryBatch.IsRunning)Repaint();}
        void OnGUI()
        {
            titleContent = new GUIContent(CHToolLanguage.Text("ASE 着色器库"));
            if(catalog==null){EditorGUILayout.HelpBox(CHToolLanguage.Text("着色器库加载失败：")+loadError,MessageType.Error);if(GUILayout.Button(CHToolLanguage.Text("重新加载")))Reload();return;}
            EditorGUILayout.LabelField(CHToolLanguage.Text("ASE 着色器库 · ")+catalog.version,EditorStyles.boldLabel);
            EditorGUILayout.LabelField(catalog.entries.Where(ShaderLibraryQuery.IsGenerated).Select(ShaderLibraryQuery.Family).Distinct().Count()+CHToolLanguage.Text(" 个同源方案 / ")+catalog.entries.Count(ShaderLibraryQuery.IsGenerated)+CHToolLanguage.Text(" 份已验证 ASE 图；三份图齐备 ")+completeFamilies.Count+CHToolLanguage.Text("；三目标功能已映射 ")+mappedFamilies.Count+CHToolLanguage.Text("。当前工程：")+activePipeline,EditorStyles.wordWrappedLabel);
            EditorGUILayout.BeginHorizontal();
            if(GUILayout.Button(CHToolLanguage.Text("刷新目录与管线")))Reload();
            if(GUILayout.Button(CHToolLanguage.Text("重置筛选")))ResetFilters();
            if(GUILayout.Button(CHToolLanguage.Text("手写 Shader 转换")))ASEShaderConverterWindow.Open();
            EditorGUILayout.EndHorizontal();
            int next=GUILayout.Toolbar(tab,new[]{CHToolLanguage.Text("ASE 着色器与材质"),CHToolLanguage.Text("来源研究与待适配 (")+catalog.research.Count+")"});
            if(next!=tab){tab=next;scroll=Vector2.zero;}
            search=EditorGUILayout.TextField(CHToolLanguage.Text("搜索（空格组合条件）"),search);
            DrawCategorySelector();pipeline=EditorGUILayout.Popup(CHToolLanguage.Text("目标管线"),pipeline,CHToolLanguage.Text(pipelines));
            if(tab==0)DrawAssets();else DrawResearch();
        }
        void DrawCategorySelector()
        {
            var rows=tab==0?assetCategories:researchCategories;
            string selected=tab==0?categoryId:researchCategoryId;
            var ids=new[]{""}.Concat(rows.Select(c=>c.id)).ToArray();
            var labels=new[]{tab==0?CHToolLanguage.Text("全部已入库分类"):CHToolLanguage.Text("全部研究分类")}.Concat(rows.Select(c=>CHToolLanguage.Text(ShaderLibraryQuery.CategoryTitle(c.id))+(tab==0?" · "+c.VersionsFor(pipeline==0?"":pipelines[pipeline])+CHToolLanguage.Text(" 份图 / 全库 ")+c.families+CHToolLanguage.Text(" 方案"):" · "+c.researchSources+CHToolLanguage.Text(" 条来源")))).ToArray();
            int index=EditorGUILayout.Popup(CHToolLanguage.Text("材质分类"),Math.Max(0,Array.IndexOf(ids,selected)),labels);
            if(tab==0)categoryId=ids[index];else researchCategoryId=ids[index];
        }
        void DrawAssets()
        {
            scope=EditorGUILayout.Popup(CHToolLanguage.Text("功能范围"),scope,new[]{CHToolLanguage.Text("全部已验证 ASE 图（含已标明的功能缺口）"),CHToolLanguage.Text("仅三目标功能已映射的方案"),CHToolLanguage.Text("仅管线缺失或有功能缺口的方案")});
            device=EditorGUILayout.Popup(CHToolLanguage.Text("目标设备"),device,CHToolLanguage.Text(deviceLabels));tier=EditorGUILayout.Popup(CHToolLanguage.Text("性能 / 复杂度"),tier,CHToolLanguage.Text(tierLabels));
            grouping=EditorGUILayout.Popup(CHToolLanguage.Text("浏览分组"),grouping,new[]{CHToolLanguage.Text("按材质分类"),CHToolLanguage.Text("按性能复杂度"),CHToolLanguage.Text("按目标设备")});
            if(GUILayout.Button(CHToolLanguage.Text("浏览完整源码效果 · 三层视差流麻"))){search="源码适配 流麻";categoryId="VFX";device=tier=scope=0;}
            if(GUILayout.Button(CHToolLanguage.Text("浏览文章方案 · 逻辑光源玉石"))){search="方木君 逻辑光源";categoryId="Jade";device=tier=scope=0;}
            var filtered=ShaderLibraryQuery.Filter(catalog,search,categoryId,pipeline==0?"":pipelines[pipeline],device==0?"":devices[device],tier==0?"":tiers[tier],(ShaderLibraryScope)scope);
            var current=filtered.Where(e=>e.pipeline==activePipeline).ToArray();
            EditorGUILayout.LabelField(CHToolLanguage.Text("匹配 ")+filtered.Select(ShaderLibraryQuery.Family).Distinct().Count()+CHToolLanguage.Text(" 个方案 / ")+filtered.Length+CHToolLanguage.Text(" 份图；当前工程可安装 ")+current.Length+CHToolLanguage.Text(" 项"));
            using(new EditorGUI.DisabledScope(ShaderLibraryBatch.IsRunning||current.Length==0))
                if(GUILayout.Button(CHToolLanguage.Text("一键安装筛选结果（Shader + .mat，当前管线 ")+current.Length+CHToolLanguage.Text(" 项）")))StartBatch(current.Select(e=>e.id).ToArray());
            if(ShaderLibraryBatch.IsRunning){EditorGUILayout.LabelField(ShaderLibraryBatch.Progress);if(GUILayout.Button(CHToolLanguage.Text("停止后续安装（保留已生成资源）")))ShaderLibraryBatch.Cancel();}
            if(!string.IsNullOrEmpty(ShaderLibraryBatch.LastReport))EditorGUILayout.LabelField(ShaderLibraryBatch.LastReport,EditorStyles.wordWrappedLabel);
            scroll=EditorGUILayout.BeginScrollView(scroll);
            EditorGUILayout.HelpBox(CHToolLanguage.Text("已验证指 ASE 保存重载和 Unity 编译通过。功能缺口及宿主依赖见各方案；未确认通用跨管线画面等价。设备与复杂度为静态建议，未实机测速，HDRP 仅 PC。"),MessageType.Info);
            DrawOverview();DrawCategoryDetails();
            if(filtered.Length==0)DrawEmptyAssets();
            IEnumerable<IGrouping<string,ShaderLibraryEntry>> groups=grouping==2
                ?devices.Skip(1).SelectMany(d=>filtered.Where(e=>e.devices.Contains(d)).Select(e=>new{device=DeviceLabel(d),entry=e})).GroupBy(x=>x.device,x=>x.entry)
                :filtered.GroupBy(e=>grouping==0?CHToolLanguage.Text(ShaderLibraryQuery.CategoryTitle(e.category)):TierLabel(e.performanceTier));
            if(grouping==2)EditorGUILayout.LabelField(CHToolLanguage.Text("同一方案可以出现在多个建议设备组。"),EditorStyles.wordWrappedLabel);
            foreach(var group in groups.OrderBy(g=>g.Key))
            {
                EditorGUILayout.Space();EditorGUILayout.LabelField(group.Key,EditorStyles.boldLabel);
                foreach(var family in group.GroupBy(ShaderLibraryQuery.Family))DrawFamily(family);
            }
            EditorGUILayout.EndScrollView();
        }
        void DrawOverview()
        {
            overview=EditorGUILayout.Foldout(overview,CHToolLanguage.Text("分类收录总览 · 查看实际图数与缺口"),true);
            if(!overview)return;
            EditorGUILayout.LabelField(CHToolLanguage.Text("以下为全库数量，不受搜索与设备筛选影响；缺版本和模型缺口分别计数。"),EditorStyles.wordWrappedLabel);
            foreach(var c in coverageCategories)
            {
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                EditorGUILayout.LabelField(CHToolLanguage.Text(ShaderLibraryQuery.CategoryTitle(c.id))+"："+c.families+CHToolLanguage.Text(" 方案 · Built-in ")+c.builtIn+" / URP "+c.urp+" / HDRP "+c.hdrp,EditorStyles.boldLabel);
                EditorGUILayout.LabelField(CHToolLanguage.Text("缺失管线版本 ")+c.missingTargets+CHToolLanguage.Text(" · 已生成但有模型/功能缺口 ")+c.featureGapTargets+CHToolLanguage.Text(" · 研究来源 ")+c.researchSources,EditorStyles.wordWrappedLabel);
                if(c.versions>0&&GUILayout.Button(CHToolLanguage.Text("浏览此分类的已入库 ASE 图"))){ResetFilters();pipeline=0;categoryId=c.id;}
                if(c.versions==0)EditorGUILayout.HelpBox(CHToolLanguage.Text("尚无已验证 ASE 图，仅有研究记录。"),MessageType.Warning);
                EditorGUILayout.EndVertical();
            }
        }
        void DrawCategoryDetails()
        {
            if(categoryId.Length==0)return;
            var c=assetCategories.FirstOrDefault(x=>x.id==categoryId);if(c==null)return;
            EditorGUILayout.LabelField(CHToolLanguage.Text(ShaderLibraryQuery.CategoryTitle(c.id))+CHToolLanguage.Text(" · 全库 ")+c.families+CHToolLanguage.Text(" 方案：Built-in ")+c.builtIn+" / URP "+c.urp+" / HDRP "+c.hdrp,EditorStyles.wordWrappedLabel);
            if(c.missingTargets+c.featureGapTargets>0)EditorGUILayout.HelpBox(CHToolLanguage.Text("此分类缺失 ")+c.missingTargets+CHToolLanguage.Text(" 个管线版本；另有 ")+c.featureGapTargets+CHToolLanguage.Text(" 个已生成版本存在模型或功能缺口。请查看方案详情。"),MessageType.Warning);
            character.Draw(categoryId,pipeline==0?activePipeline:pipelines[pipeline]);
            if(c.researchSources>0&&GUILayout.Button(CHToolLanguage.Text("查看此分类的来源与待适配记录（")+c.researchSources+CHToolLanguage.Text(" 条）"))){tab=1;researchCategoryId=categoryId;search="";pipeline=0;scroll=Vector2.zero;}
        }
        void DrawEmptyAssets()
        {
            var inCategory=ShaderLibraryQuery.Filter(catalog,category:categoryId);
            string selectedPipeline=pipeline==0?"":pipelines[pipeline];
            bool missing=selectedPipeline.Length>0&&!inCategory.Any(e=>e.pipeline==selectedPipeline);
            EditorGUILayout.HelpBox(missing?CHToolLanguage.Text("此分类尚未收录 ")+selectedPipeline+CHToolLanguage.Text(" 的已验证 ASE 版本。其他管线有 ")+inCategory.Length+CHToolLanguage.Text(" 份图，不能在当前管线直接安装。"):CHToolLanguage.Text("当前搜索、设备、复杂度或功能范围组合没有匹配项。此结果不代表该分类没有收录 Shader。"),MessageType.Warning);
            if(GUILayout.Button(CHToolLanguage.Text("查看此分类全部已验证版本（清除搜索与限制）"))){search="";pipeline=device=tier=scope=0;}
        }
        void DrawFamily(IEnumerable<ShaderLibraryEntry> family)
        {
            string id=ShaderLibraryQuery.Family(family.First());
            var all=catalog.entries.Where(e=>ShaderLibraryQuery.Family(e)==id).ToArray();
            var contract=catalog.familyContracts.FirstOrDefault(c=>c.familyId==id);
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            bool open;expanded.TryGetValue(id,out open);open=EditorGUILayout.Foldout(open,family.First().title,true);expanded[id]=open;
            EditorGUILayout.LabelField(ShaderLibraryQuery.Coverage(all,contract),EditorStyles.wordWrappedLabel);
            if(open)
            {
                if(contract!=null)
                {
                    EditorGUILayout.LabelField(CHToolLanguage.Text("同源身份：")+contract.sourceIdentity,EditorStyles.wordWrappedLabel);
                    EditorGUILayout.LabelField(CHToolLanguage.Text("共同功能：")+string.Join("；",contract.sharedFeatures.ToArray()),EditorStyles.wordWrappedLabel);
                    foreach(var target in contract.targets)
                    {
                        if(target.gaps.Count>0)EditorGUILayout.HelpBox(target.pipeline+"："+string.Join("；",target.gaps.ToArray()),MessageType.Warning);
                        if(target.hostRequirements.Count>0)EditorGUILayout.LabelField(target.pipeline+CHToolLanguage.Text(" 宿主：")+string.Join("；",target.hostRequirements.ToArray()),EditorStyles.wordWrappedLabel);
                    }
                }
                foreach(var entry in family.OrderBy(e=>e.pipeline))Draw(entry);
            }
            EditorGUILayout.EndVertical();
        }
        void DrawResearch()
        {
            var rows=catalog.research.Where(e=>ShaderLibraryQuery.MatchesResearch(e,search,researchCategoryId,pipeline==0?"":pipelines[pipeline])).ToArray();
            EditorGUILayout.LabelField(CHToolLanguage.Text("匹配 ")+rows.Length+CHToolLanguage.Text(" 条研究来源（来源可以属于多个分类）"));
            scroll=EditorGUILayout.BeginScrollView(scroll);
            EditorGUILayout.HelpBox(CHToolLanguage.Text("研究记录包含尚未转换的 Shader、Shader Graph、依赖和方案。此处条数不代表可安装的 ASE Shader；已生成版本请在着色器页查看。"),MessageType.Info);
            if(researchCategoryId.Length>0)
            {
                var c=researchCategories.FirstOrDefault(x=>x.id==researchCategoryId);
                if(c!=null)EditorGUILayout.LabelField(CHToolLanguage.Text("此分类实际入库：")+c.families+CHToolLanguage.Text(" 方案 / ")+c.versions+CHToolLanguage.Text(" 份 ASE 图。研究清单与生成清单分别计数。"),EditorStyles.wordWrappedLabel);
                using(new EditorGUI.DisabledScope(c==null||c.versions==0))
                    if(GUILayout.Button(CHToolLanguage.Text("查看此分类已入库的 ASE 图"))){categoryId=researchCategoryId;tab=0;search="";pipeline=device=tier=scope=0;scroll=Vector2.zero;}
                character.Draw(researchCategoryId,pipeline==0?activePipeline:pipelines[pipeline]);
            }
            if(rows.Length==0)EditorGUILayout.HelpBox(CHToolLanguage.Text("当前分类、管线或搜索条件没有匹配的研究记录。可重置筛选重新浏览。"),MessageType.Info);
            foreach(var e in rows)
            {
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);EditorGUILayout.LabelField(e.title+" · "+e.kind+" · "+e.status,EditorStyles.boldLabel);
                EditorGUILayout.LabelField(e.source,EditorStyles.wordWrappedLabel);EditorGUILayout.LabelField(CHToolLanguage.Text("许可：")+e.license,EditorStyles.wordWrappedLabel);
                EditorGUILayout.LabelField(string.Join("；",e.blockers.ToArray()),EditorStyles.wordWrappedLabel);EditorGUILayout.EndVertical();
            }
            EditorGUILayout.EndScrollView();
        }
        static string TierLabel(string value){return value=="Low"?CHToolLanguage.Text("低复杂度"):value=="Medium"?CHToolLanguage.Text("中复杂度"):value=="High"?CHToolLanguage.Text("高复杂度"):CHToolLanguage.Text("未分级");}
        static string DeviceLabel(string value){return value=="Mobile"?CHToolLanguage.Text("移动端"):value=="Pad"?CHToolLanguage.Text("Pad 平板"):value;}
        static void StartBatch(string[] ids){try{ShaderLibraryBatch.Start(ids);}catch(Exception ex){EditorUtility.DisplayDialog(CHToolLanguage.Text("无法生成材质"),ex.Message,CHToolLanguage.Text("确定"));}}
        void Draw(ShaderLibraryEntry e)
        {
            EditorGUILayout.LabelField(e.pipeline+" · "+TierLabel(e.performanceTier)+" · "+string.Join(" / ",e.devices.Select(DeviceLabel).ToArray())+CHToolLanguage.Text("（未实机测速）"));
            EditorGUILayout.LabelField(CHToolLanguage.Text("原生节点 ")+e.nativeNodeCount+CHToolLanguage.Text(" / 采样位置 ")+e.textureSampleSites+CHToolLanguage.Text(" / 中文注释 ")+e.commentCount+CHToolLanguage.Text("；ASE 重载、Unity 编译通过"));
            EditorGUILayout.LabelField(e.effect+" "+e.notes,EditorStyles.wordWrappedLabel);
            EditorGUILayout.LabelField(CHToolLanguage.Text("复杂度依据：")+e.performanceBasis,EditorStyles.wordWrappedLabel);
            EditorGUILayout.LabelField(CHToolLanguage.Text("设备要求：")+e.deviceRequirements,EditorStyles.wordWrappedLabel);
            if(e.dependencies.Count>0)EditorGUILayout.LabelField(CHToolLanguage.Text("依赖：")+string.Join("；",e.dependencies.ToArray()),EditorStyles.wordWrappedLabel);
            using(new EditorGUI.DisabledScope(ShaderLibraryBatch.IsRunning||e.pipeline!=activePipeline))
                if(GUILayout.Button(CHToolLanguage.Text("安装此项 Shader + 材质")))StartBatch(new[]{e.id});
            if(e.origin=="ReviewedMaterialAdaptation")
            {
                showcasePreset=EditorGUILayout.Popup(CHToolLanguage.Text("流麻配色预设"),showcasePreset,new[]{CHToolLanguage.Text("蓝青闪片"),CHToolLanguage.Text("金橙闪片"),CHToolLanguage.Text("紫色闪片")});
                var material=Selection.activeObject as Material;
                bool matching=material!=null&&material.shader!=null&&material.shader.name=="ASELibrary/"+e.pipeline+"/Showcase/LayeredParallaxGlitter";
                using(new EditorGUI.DisabledScope(!matching||ShaderLibraryBatch.IsRunning||e.pipeline!=activePipeline))
                    if(GUILayout.Button(CHToolLanguage.Text("应用预设到选中的流麻材质"))){Undo.RecordObject(material,"Apply glitter preset");ShowcaseMaterialPresets.Apply(material,showcasePreset);EditorUtility.SetDirty(material);}
                EditorGUILayout.LabelField(CHToolLanguage.Text("先安装并选中流麻 .mat，再应用配色预设。三种配色使用同一套 Shader。"),EditorStyles.wordWrappedLabel);
            }
            if(e.id=="original-BuiltIn-DeepWater")using(new EditorGUI.DisabledScope(ShaderLibraryBatch.IsRunning||e.pipeline!=activePipeline))
                if(GUILayout.Button(CHToolLanguage.Text("安装完整 DeepWater 配套工具")))try{ShaderLibraryAssets.Import(e.id);}catch(Exception ex){EditorUtility.DisplayDialog(CHToolLanguage.Text("水面工具"),ex.Message,CHToolLanguage.Text("确定"));}
        }
    }
}
