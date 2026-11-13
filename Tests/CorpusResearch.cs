using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text.Json;
using System.Text.RegularExpressions;
using ASEShaderConverter;

// Data-only research runner. Never starts Unity, imports assets, or generates shaders.
internal static class CorpusResearch
{
    private static readonly JsonSerializerOptions Json = new JsonSerializerOptions { IncludeFields=true, WriteIndented=true };
    private static int analysisErrors;
    private static string Hash(string path) { return Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(path))).ToLowerInvariant(); }
    public static int Main(string[] args)
    {
        if(args.Length >= 2 && args[0]=="--semantic-audit")
        {
            var results=SemanticCompletenessChecks.Evaluate();
            var auditSummary=new { probeCount=SemanticCompletenessChecks.Probes().Count, targetEvaluations=results.Count,
                passed=results.Count(r=>r.passed), failed=results.Count(r=>!r.passed), generatedShaders=0,
                aseSaveReloadPerformed=false, unityShaderCompilationPerformed=false, visualComparisonPerformed=false };
            Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(args[1])));
            File.WriteAllText(args[1],JsonSerializer.Serialize(new { summary=auditSummary, probes=SemanticCompletenessChecks.Probes(), results },Json));
            Console.WriteLine(JsonSerializer.Serialize(auditSummary,Json));
            return auditSummary.failed==0 || args.Contains("--record-only")?0:1;
        }
        if(args.Length>0 && args[0]=="--function-probes") return FunctionCorpusResearch.Run(args);
        if(args.Length < 2 || args.Length > 3) throw new ArgumentException("Usage: CorpusResearch <manifest.json> <evidence-directory> [user-shader-directory]");
        string manifestPath=Path.GetFullPath(args[0]), output=Path.GetFullPath(args[1]);
        string corpusRoot=Path.GetDirectoryName(manifestPath);
        using var manifest=JsonDocument.Parse(File.ReadAllText(manifestPath));
        var rows=new List<object>();
        var statuses=new Dictionary<string,int>(StringComparer.Ordinal);
        var coverage=new Dictionary<string,int>(StringComparer.Ordinal);
        int shaderCount=0, includeCount=0, localCount=0;
        var identities=new HashSet<string>(StringComparer.Ordinal);
        foreach(var repo in manifest.RootElement.GetProperty("repositories").EnumerateArray())
        {
            if (repo.TryGetProperty("success",out var success) && !success.GetBoolean()) continue;
            string repository=repo.GetProperty("repository").GetString(), commit=repo.GetProperty("commit").GetString();
            foreach(var file in repo.GetProperty("files").EnumerateArray())
            {
                string relative=file.GetProperty("path").GetString();
                if(!identities.Add(repository+"@"+commit+":"+relative)) continue;
                // Resolve from manifest directory, not the original machine's absolute download path.
                string path=Path.GetFullPath(Path.Combine(corpusRoot, repository.Replace("/","--"), relative));
                if(!path.StartsWith(corpusRoot+Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Path escapes corpus root");
                string hash=Hash(path);
                if(hash!=file.GetProperty("sha256").GetString()) throw new InvalidDataException("Corpus hash mismatch: "+relative);
                string role=repo.TryGetProperty("evaluationRole",out var roleValue) && roleValue.ValueKind==JsonValueKind.String?roleValue.GetString():"ExistingCorpus";
                rows.Add(Inspect(path,repository,relative,commit,file.GetProperty("url").GetString(),repo.GetProperty("license").GetString(),hash,statuses,coverage,role));
                if(Path.GetExtension(path).Equals(".shader",StringComparison.OrdinalIgnoreCase)) shaderCount++; else includeCount++;
            }
        }
        var userRows=new List<object>();
        if(args.Length==3)
        {
            string directory=Path.GetFullPath(args[2]);
            foreach(string name in new[]{"BillBordScale.shader","bubble.shader","Custom2TexStencilmask.shader","Custom2TexV2.shader","Dissolve_add.shader","Fresnel_A.shader","PBR.shader","PBR_OutLine.shader","RotateAroundCenter.shader","TransMovie.shader","Vertex offset.shader"})
            {
                string path=Path.Combine(directory,name);
                userRows.Add(Inspect(path,"user-reference",name,"","","Private/read-only; not distributed",Hash(path),new Dictionary<string,int>(),new Dictionary<string,int>()));
                localCount++;
            }
        }
        Directory.CreateDirectory(output);
        var summary=new {
            schemaVersion=1, libraryVersion=ShaderRuleLibrary.Version, analyzedUtc=DateTimeOffset.UtcNow,
            manifestSha256=Hash(manifestPath), publicSourceFiles=shaderCount+includeCount, publicShaderFiles=shaderCount, publicIncludeFiles=includeCount,
            userReferenceFiles=localCount, publicStatuses=statuses, publicRuleCoverage=coverage,analysisErrors,
            unavailableRepositories=manifest.RootElement.GetProperty("repositories").EnumerateArray().Where(r=>r.TryGetProperty("success",out var s) && !s.GetBoolean()).Select(r=>new{repository=r.GetProperty("repository").GetString(),error=r.GetProperty("error").GetString()}).ToArray(),
            generatedShaders=0, aseSaveReloadPerformed=false, unityShaderCompilationPerformed=false, visualComparisonPerformed=false,
            note="Planned means an unvalidated native-node plan. RecipeRecorded is knowledge, not executable conversion support. Source files were not changed. Includes are inventoried without preprocessing or import."
        };
        File.WriteAllText(Path.Combine(output,"public-corpus-analysis.json"),JsonSerializer.Serialize(new{summary,files=rows},Json));
        File.WriteAllText(Path.Combine(output,"user-reference-analysis.json"),JsonSerializer.Serialize(new{libraryVersion=ShaderRuleLibrary.Version,generatedShaders=0,files=userRows},Json));
        File.WriteAllText(Path.Combine(output,"rule-catalog.json"),JsonSerializer.Serialize(ShaderRuleLibrary.Catalog(),Json));
        Console.WriteLine(JsonSerializer.Serialize(summary,Json));
        return analysisErrors==0?0:1;
    }

    private static object Inspect(string path,string repository,string relative,string commit,string url,string license,string hash,Dictionary<string,int> statuses,Dictionary<string,int> coverage,string evaluationRole="UserReference")
    {
        string source=File.ReadAllText(path);
        var knowledge=ShaderRuleLibrary.Review(source);
        bool shader=Path.GetExtension(path).Equals(".shader",StringComparison.OrdinalIgnoreCase);
        ShaderConversionAnalysis analysis=null;
        string analysisError="";
        try { if(shader) analysis=ShaderConversionEngine.Analyze(source,relative); }
        catch(Exception e) { analysisError=e.GetType().Name+": "+e.Message; analysisErrors++; }
        string status=shader?(analysis==null?"AnalysisError":analysis.report.status):"IncludeInventoried";
        if(!statuses.ContainsKey(status)) statuses[status]=0;
        statuses[status]++;
        foreach(var rule in knowledge.rules) { if(!coverage.ContainsKey(rule.id)) coverage[rule.id]=0; coverage[rule.id]++; }
        string[] includes=Regex.Matches(source,"#\\s*include\\s*\"([^\"]+)\"").Cast<Match>().Select(m=>m.Groups[1].Value).Distinct().ToArray();
        string[] helpers=Regex.Matches(source,@"\b(?:inline\s+)?(?:float|half|fixed)[1-4]?\s+(\w+)\s*\([^;{}]*\)\s*\{").Cast<Match>().Select(m=>m.Groups[1].Value).ToArray();
        if(Hash(path)!=hash) throw new IOException("Source changed during analysis: "+path);
        if(analysis!=null && (analysis.report.status=="Generated" || analysis.report.aseRoundTripPassed || analysis.report.shaderCompiled || analysis.report.visualComparisonPassed)) throw new InvalidOperationException("Analysis must not claim generation or validation");
        var targets=new List<object>();
        if(shader)
            foreach(string pipeline in new[]{"BuiltIn","URP","HDRP"})
            {
                try
                {
                    var target=ShaderConversionEngine.Analyze(source,relative,new ShaderConversionOptions{targetPipeline=pipeline});
                    var errors=target.report.CanGenerate?ShaderGraphValidator.Validate(target.plan):new List<string>();
                    if(errors.Count>0) analysisErrors++;
                    targets.Add(new{pipeline,sourcePipeline=target.report.sourcePipeline,status=target.report.status,canPlan=target.report.CanGenerate,nodeCount=target.plan.nodes.Count,blockers=target.report.blockers,planErrors=errors,
                        aseSaveReloadPerformed=false,unityShaderCompilationPerformed=false,visualComparisonPerformed=false});
                }
                catch(Exception e) { analysisErrors++; targets.Add(new{pipeline,status="AnalysisError",error=e.GetType().Name+": "+e.Message}); }
            }
        return new {
            repository,path=relative,commit,url,license,licenseScope="Root/repository metadata; per-file notices can differ. Research only; sources not distributed.",sha256=hash,sourceUnchanged=true,status,evaluationRole,analysisError,
            canPlan=analysis!=null && analysis.report.CanGenerate,
            planNodeCount=analysis==null?0:analysis.plan.nodes.Count,
            planErrors=analysis!=null && analysis.report.CanGenerate?ShaderGraphValidator.Validate(analysis.plan):new List<string>(),
            blockers=analysis==null?new List<string>():analysis.report.blockers,
            warnings=analysis==null?new List<string>():analysis.report.warnings,
            sourcePipeline=analysis==null?"":analysis.report.sourcePipeline,targets,
            includes,helperDefinitions=helpers,overloadedHelperNames=helpers.GroupBy(n=>n).Where(g=>g.Count()>1).Select(g=>g.Key).ToArray(),knowledge
        };
    }
}
