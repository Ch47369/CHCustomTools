using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text.Json;
using System.Text.RegularExpressions;
using ASEShaderConverter;

// Extract complete math helper definitions as data. These probes assess mathematical
// subgraphs only, never claim to preprocess an include or convert its parent shader.
internal static class FunctionCorpusResearch
{
    private static string Hash(string path) { return Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(path))).ToLowerInvariant(); }
    private static string Extract(string source)
    {
        var definitions=new List<string>();
        foreach(Match match in Regex.Matches(source,@"\b(?:float|half|fixed)[1-4]?\s+\w+\s*\([^;{}]*\)\s*\{"))
        {
            int open=source.IndexOf('{',match.Index),depth=1,end=open+1;
            for(;end<source.Length && depth>0;end++) { if(source[end]=='{') depth++; if(source[end]=='}') depth--; }
            if(depth!=0) throw new InvalidDataException("Unbalanced probe helper");
            definitions.Add(source.Substring(match.Index,end-match.Index));
        }
        return string.Join("\n",definitions);
    }
    private static double[] Evaluate(ShaderGraphPlan plan)
    {
        var values=new Dictionary<string,double[]>();
        Func<string,double[]> eval=null;
        eval=id=> {
            double[] cached;
            if(values.TryGetValue(id,out cached)) return cached;
            var node=plan.nodes.Single(n=>n.id==id);
            var args=plan.wires.Where(w=>w.to==id).OrderBy(w=>int.Parse(w.toPort,CultureInfo.InvariantCulture)).Select(w=>eval(w.from)).ToArray();
            Func<Func<double[],double>,double[]> map=f=>Enumerable.Range(0,args.Max(a=>a.Length)).Select(c=>f(args.Select(a=>a[a.Length==1?0:c]).ToArray())).ToArray();
            double[] result;
            switch(node.type)
            {
                case "RangedFloatNode": result=new[]{double.Parse(node.value,CultureInfo.InvariantCulture)}; break;
                case "DynamicAppendNode": result=args.SelectMany(a=>a).ToArray(); break;
                case "SwizzleNode": result=node.swizzle.Select(c=>args[0]["xyzw".IndexOf(c)]).ToArray(); break;
                case "NegateNode": result=map(a=>-a[0]); break;
                case "SimpleAddOpNode": result=map(a=>a[0]+a[1]); break;
                case "SimpleSubtractOpNode": result=map(a=>a[0]-a[1]); break;
                case "SimpleMultiplyOpNode": result=map(a=>a[0]*a[1]); break;
                case "SimpleDivideOpNode": result=map(a=>a[0]/a[1]); break;
                case "FloorOpNode": result=map(a=>Math.Floor(a[0])); break;
                case "FractNode": result=map(a=>a[0]-Math.Floor(a[0])); break;
                case "SinOpNode": result=map(a=>Math.Sin(a[0])); break;
                case "SaturateNode": result=map(a=>Math.Max(0,Math.Min(1,a[0]))); break;
                case "LerpOp": result=map(a=>a[0]+a[2]*(a[1]-a[0])); break;
                default: throw new InvalidOperationException("Independent evaluator missing node: "+node.type);
            }
            values.Add(id,result); return result;
        };
        return eval(plan.outputs.Single(o=>o.masterPort=="Color").node);
    }
    private static double Mod289(double x) { return x-Math.Floor(x/289)*289; }
    private static double Permute(double x) { return Mod289((x*34+10)*x); }
    private static double Fade(double x) { return x*x*x*(x*(x*6-15)+10); }
    private static double Reference(string id)
    {
        if(id.StartsWith("wglnoise_mod/",StringComparison.Ordinal)) return -291.37-2*Math.Floor(-291.37/2);
        if(id.StartsWith("wglnoise_mod289/",StringComparison.Ordinal)) return Mod289(-291.37);
        if(id.StartsWith("wglnoise_permute/",StringComparison.Ordinal)) return Permute(-291.37);
        if(id.StartsWith("wglnoise_fade/",StringComparison.Ordinal)) return Fade(0.37);
        if(id.StartsWith("GradientNoise/",StringComparison.Ordinal))
        {
            double seed=id.EndsWith("/1",StringComparison.Ordinal)?1:2;
            double x=0.37,f=x-Math.Floor(x),blend=Fade(f);
            double n0=Math.Sin(Permute(Permute(Mod289(Math.Floor(x)))+seed)/41*3.14159265359*2)*f;
            double n1=Math.Sin(Permute(Permute(Mod289(Math.Floor(x+1)))+seed)/41*3.14159265359*2)*(f-1);
            return 2*(n0+(n1-n0)*blend);
        }
        return id=="remap"?-0.63:0.185;
    }
    public static int Run(string[] args)
    {
        if(args.Length!=3) throw new ArgumentException("Usage: --function-probes <corpus-root> <report.json>");
        string root=Path.GetFullPath(args[1]);
        string commonPath=Path.Combine(root,"keijiro--NoiseShader/Packages/jp.keijiro.noiseshader/Shader/Common.hlsl");
        string noisePath=Path.Combine(root,"keijiro--NoiseShader/Packages/jp.keijiro.noiseshader/Shader/Noise1D.hlsl");
        string remapPath=Path.Combine(root,"ColinLeung-NiloCat--UnityURPToonLitShaderExample/NiloInvLerpRemap.hlsl");
        string common=Extract(File.ReadAllText(commonPath)),noise=Extract(File.ReadAllText(noisePath)),remap=Extract(File.ReadAllText(remapPath));
        var probes=new List<(string id,string expression,int width,string helpers,string[] paths)>();
        foreach(var function in new[]{("wglnoise_mod",1,4),("wglnoise_fade",1,3),("wglnoise_mod289",1,4),("wglnoise_permute",2,4)})
            for(int width=function.Item2;width<=function.Item3;width++)
            {
                string sample=function.Item1=="wglnoise_fade"?"0.37":"-291.37";
                string value=width==1?sample:"float"+width+"("+sample+")";
                string other=width==1?"2.0":"float"+width+"(2.0)";
                probes.Add((function.Item1+"/"+width,function.Item1+"("+value+(function.Item1=="wglnoise_mod"?","+other:"")+")",width,common,new[]{commonPath}));
            }
        probes.Add(("GradientNoise/1","GradientNoise(0.37)",1,common+noise,new[]{commonPath,noisePath}));
        probes.Add(("GradientNoise/2","GradientNoise(0.37,2.0)",1,common+noise,new[]{commonPath,noisePath}));
        probes.Add(("invLerp","invLerp(0.0,2.0,0.37)",1,remap,new[]{remapPath}));
        probes.Add(("invLerpClamp","invLerpClamp(0.0,2.0,0.37)",1,remap,new[]{remapPath}));
        probes.Add(("remap","remap(0.0,2.0,-1.0,1.0,0.37)",1,remap,new[]{remapPath}));
        var rows=new List<object>(); int planned=0,numericalChecks=0;
        foreach(var probe in probes)
        {
            string expression=probe.width==4?probe.expression:"float4("+probe.expression+(probe.width==1?",0.0,0.0,1.0)":probe.width==2?",0.0,1.0)":",1.0)");
            string wrapper="Shader \"Research/MathProbe\" { SubShader { Pass { CGPROGRAM\n#pragma vertex vert\n#pragma fragment frag\n#include \"UnityCG.cginc\"\n"+probe.helpers+@"
struct Mesh { float4 position : POSITION; }; struct Raster { float4 clip : SV_POSITION; };
Raster vert(Mesh mesh) { Raster output; output.clip=UnityObjectToClipPos(mesh.position); return output; }
float4 frag(Raster input) : SV_Target { return "+expression+"; }\nENDCG } } }";
            var analysis=ShaderConversionEngine.Analyze(wrapper);
            var errors=analysis.report.CanGenerate?ShaderGraphValidator.Validate(analysis.plan):new List<string>();
            if(errors.Count>0) throw new InvalidOperationException("Invalid probe graph: "+probe.id);
            double[] actual=null,expected=Enumerable.Repeat(Reference(probe.id),probe.width).Concat(probe.width<3?new double[3-probe.width]:new double[0]).Take(3).ToArray();
            if(analysis.report.CanGenerate)
            {
                planned++; actual=Evaluate(analysis.plan);
                if(actual.Length!=expected.Length || actual.Zip(expected,(a,b)=>Math.Abs(a-b)<=1e-6*Math.Max(1,Math.Abs(b))).Any(equal=>!equal))
                    throw new InvalidOperationException("Function numeric dataflow mismatch: "+probe.id);
                numericalChecks++;
            }
            rows.Add(new{probe.id,probe.expression,scope="FunctionOnly",canPlan=analysis.report.CanGenerate,status=analysis.report.status,nodes=analysis.plan.nodes.Count,
                blockers=analysis.report.blockers,numericalCheck=analysis.report.CanGenerate?"PassedDotNetReference":"NotPlanned",actual,expected,sourceFiles=probe.paths.Select(p=>new{path=Path.GetRelativePath(root,p).Replace('\\','/'),sha256=Hash(p)}).ToArray()});
        }
        var report=new{libraryVersion=(string)typeof(ShaderRuleLibrary).GetField("Version").GetRawConstantValue(),probeCount=probes.Count,planned,numericalChecks,generatedShaders=0,
            note="Function-only extraction; wrappers exist only in memory. Double-precision .NET reference dataflow checks do not model GPU precision/quantization. Parent shaders/includes retain all stage, dependency and render-state blockers. No ASE generation, shader execution or rendering.",probes=rows};
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(args[2])));
        File.WriteAllText(args[2],JsonSerializer.Serialize(report,new JsonSerializerOptions{WriteIndented=true}));
        Console.WriteLine("Function-only probes: "+planned+"/"+probes.Count+" planned; no shaders generated.");
        return 0;
    }
}
