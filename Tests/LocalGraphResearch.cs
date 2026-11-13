using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text.Json;
using ASEShaderConverter;

static class LocalGraphResearch
{
    static string Hash(string p){return Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(p))).ToLowerInvariant();}
    public static void Main(string[] args)
    {
        string root=Path.GetFullPath(".");using var manifest=JsonDocument.Parse(File.ReadAllText(args[0]));
        var rows=new List<object>();int errors=0;
        foreach(var row in manifest.RootElement.GetProperty("rows").EnumerateArray().GroupBy(r=>r.GetProperty("sha256").GetString()).Select(g=>g.First()))
        {
            string path=Path.Combine(root,row.GetProperty("cachedSource").GetString()),expected=row.GetProperty("sha256").GetString(),kind=row.GetProperty("kind").GetString();
            if(Hash(path)!=expected)throw new Exception("Source hash mismatch");
            string source=File.ReadAllText(path);var analyses=new List<ShaderConversionAnalysis>();
            string error="";
            if(kind=="shadergraph"||kind=="shadersubgraph"||kind=="shader")
            {
                try{foreach(string target in new[]{"BuiltIn","URP","HDRP"})analyses.Add(ShaderConversionEngine.Analyze(source,row.GetProperty("path").GetString(),new ShaderConversionOptions{targetPipeline=target}));}
                catch(Exception e){error=e.Message;errors++;}
            }
            if(Hash(path)!=expected)throw new Exception("Source changed");
            rows.Add(new{sha256=expected,kind,sourceUnchanged=true,error,analyses});
        }
        var options=new JsonSerializerOptions{IncludeFields=true,WriteIndented=true};
        string output=Path.GetFullPath(args[1]);Directory.CreateDirectory(output);
        File.WriteAllText(Path.Combine(output,"core-analysis.json"),JsonSerializer.Serialize(new{libraryVersion=ShaderRuleLibrary.Version,uniqueSources=rows.Count,errors,generatedShaders=0,rows},options));
        Console.WriteLine("Local sources analyzed: "+rows.Count+"; exceptions="+errors+"; generated=0");
        if(errors>0)Environment.Exit(1);
    }
}
