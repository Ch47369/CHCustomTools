// Validates the character catalog/API and describes installed templates. Does not generate character shaders.
using System;
using System.IO;
using System.Linq;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;

public static class UnityCharacterLibrarySmoke
{
    static string output;
    static void Save(string name,object value){File.WriteAllText(Path.Combine(output,name),JsonUtility.ToJson(value,true));}
    static void Check(bool condition,string message){if(!condition)throw new Exception(message);}
    public static void Run()
    {
        try
        {
            Check(Path.GetFullPath(".").IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)>=0,"Isolation required");
            output=Path.GetFullPath("CharacterLibraryEvidence");Directory.CreateDirectory(output);
            var probe=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});Save("probe.json",probe);
            Check(probe.success,"Probe failed: "+probe.error);
            Check(probe.environment.activePipeline=="HDRP","Use HDRP isolation project");
            var rules=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="rules"});Save("rules.json",rules);
            Check(rules.success && rules.ruleLibrary.characterProfiles.Count==4 && rules.ruleLibrary.categories.Any(c=>c.id=="Eye"),"Catalog/API incomplete");
            foreach(var profile in rules.ruleLibrary.characterProfiles)
            {
                var response=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="analyze",sourceText="Shader \"Character/"+profile.id+"\" { SubShader { Pass { HLSLPROGRAM\n#pragma vertex vert\n#pragma fragment frag\n#include \"Packages/com.unity.render-pipelines.high-definition/Runtime/Material/"+(profile.id=="Skin"?"Lit":profile.id)+"/"+(profile.id=="Skin"?"Lit":profile.id)+".hlsl\"\nENDHLSL } } }",options=new ShaderConversionOptions{targetPipeline="HDRP"}});
                Save("analyze-"+profile.id+".json",response);
                Check(response.analysis.knowledge.characterMaterials.Any(c=>c.profileId==profile.id),"Missing character profile "+profile.id);
                Check(!response.success && !response.report.aseRoundTripPassed && !response.report.shaderCompiled,"Unsupported character input must not become generated");
            }
            foreach(var named in new[]{new[]{"Hair","e4fe21624ace6de4b9fbaabdda0c51de"},new[]{"Fabric","41e04be03f2c20941bc749271be1c937"}})
            {
                Check(probe.environment.templates.Any(t=>t.guid==named[1] && t.ready),"Installed "+named[0]+" template not active");
                var description=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="describe",templateGuid=named[1],nodeTypes=new[]{"SamplerNode","VertexColorNode"}});Save("describe-"+named[0]+".json",description);
                Check(description.success && description.description.masters.Count>0,"Could not describe "+named[0]);
            }
            var lit=probe.environment.templates.Where(t=>t.ready && t.name.IndexOf("Lit",StringComparison.OrdinalIgnoreCase)>=0 && t.name.IndexOf("Unlit",StringComparison.OrdinalIgnoreCase)<0 && t.path.IndexOf("HDRP",StringComparison.OrdinalIgnoreCase)>=0).ToArray();
            Check(lit.Length>0,"HDRP Lit template absent");
            foreach(var template in lit)
            {
                var description=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="describe",templateGuid=template.guid,nodeTypes=new[]{"SamplerNode"}});Save("describe-Lit-"+template.guid+".json",description);
                Check(description.success,"Could not describe HDRP Lit");
            }
            CharacterMaterialWindow.Open();var window=Resources.FindObjectsOfTypeAll<CharacterMaterialWindow>().Single();window.Repaint();window.Close();
            File.WriteAllText(Path.Combine(output,"result.txt"),"PASS: 4 profiles through rules/analyze; unsupported character inputs remain blocked; actual HDRP Hair/Fabric/Lit templates described; Editor window created/closed. No character ASE generation, shader compilation, source-scene comparison or GPU benchmark.");
            Debug.Log("ASE_CHARACTER_LIBRARY_SMOKE_PASS");EditorApplication.Exit(0);
        }
        catch(Exception e){Debug.LogException(e);EditorApplication.Exit(1);}
    }
}
