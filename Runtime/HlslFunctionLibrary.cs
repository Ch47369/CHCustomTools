using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace ASEShaderConverter
{
    internal sealed class HlslLocalFunction
    {
        public string name, returnType, body, error;
        public readonly List<string> parameters = new List<string>(), parameterTypes = new List<string>();
        public string Signature { get { return name + "(" + string.Join(",", parameterTypes.ToArray()) + ")"; } }
    }

    // Reusable syntax rules, not source-name/signature exemptions. Only side-effect-free,
    // float arithmetic helpers are admitted; the normal stage/render-state checks still apply.
    internal sealed class HlslFunctionLibrary
    {
        private readonly Dictionary<string, List<HlslLocalFunction>> functions = new Dictionary<string, List<HlslLocalFunction>>(StringComparer.Ordinal);
        private const string Reserved = "length distance saturate abs normalize sin cos tan sqrt frac floor round ceil pow lerp dot cross min max step smoothstep clamp exp exp2 log log2 log10 rcp rsqrt sign trunc fmod atan atan2 asin acos tex2D tex2Dlod sample_texture2d unity_sample_tex2darray_lod UnityObjectToClipPos TransformObjectToHClip TRANSFORM_TEX";
        public HlslFunctionLibrary(string source)
        {
            var entries = new HashSet<string>(Regex.Matches(source, @"#pragma\s+(?:vertex|fragment)\s+(\w+)").Cast<Match>().Select(m => m.Groups[1].Value));
            foreach (Match match in Regex.Matches(source, @"\b(?<type>\w+)\s+(?<name>\w+)\s*\((?<params>[^{};]*)\)\s*\{"))
            {
                string name = match.Groups["name"].Value;
                if (entries.Contains(name)) continue;
                var function = new HlslLocalFunction { name = name, returnType = Type(match.Groups["type"].Value) };
                List<HlslLocalFunction> group;
                if (!functions.TryGetValue(name, out group)) functions.Add(name, group = new List<HlslLocalFunction>());
                group.Add(function);
                if (!Regex.IsMatch(match.Groups["type"].Value, @"^(?:float|half|fixed)[1-4]?$"))
                { function.error = "Helper return type requires an explicit numeric/resource type mapping."; continue; }
                int open = source.IndexOf('{', match.Index + match.Length - 1), close = ShaderText.FindMatchingBrace(source, open);
                if (close < 0) { function.error = "Unbalanced helper function."; continue; }
                if (Reserved.Split(' ').Any(n => string.Equals(n, name, StringComparison.OrdinalIgnoreCase))) { function.error = "A helper cannot replace an intrinsic mapping."; continue; }
                string parameters = match.Groups["params"].Value.Trim();
                foreach (string parameter in parameters.Length == 0 ? new string[0] : parameters.Split(','))
                {
                    Match parsed = Regex.Match(parameter.Trim(), @"^(?:in\s+)?(?<type>(?:float|half|fixed)[1-4]?)\s+(?<name>\w+)$");
                    if (!parsed.Success || function.parameters.Contains(parsed.Groups["name"].Value)) { function.error = "Helpers require unique float scalar/vector value parameters; out/inout/arrays are not adapted."; break; }
                    function.parameters.Add(parsed.Groups["name"].Value); function.parameterTypes.Add(Type(parsed.Groups["type"].Value));
                }
                try
                {
                    function.body = ExpandBoundedLoops(source.Substring(open + 1, close - open - 1));
                    if (Regex.IsMatch(function.body, @"[#{}]|\b(?:if|else|while|switch|discard|clip|break|continue|do|int|uint|bool|sampler\w*|tex\w*|SAMPLE_\w*|UNITY_\w*)\b"))
                        function.error = "Helper control flow, texture sampling, integer operations or side effects need explicit mapping.";
                    var statements = Statements(function.body);
                    if (statements.Length == 0 || !statements.Last().StartsWith("return ", StringComparison.Ordinal) || statements.Count(s => Regex.IsMatch(s, @"^return\b")) != 1)
                        function.error = "A helper requires one final return.";
                    foreach (string statement in statements.Take(Math.Max(0, statements.Length - 1)))
                        if (!Regex.IsMatch(statement, @"^(?:(?:const\s+)?(?:float|half|fixed)[1-4]?\s+\w+\s*=|\w+(?:\.[xyzwrgba]{1,4})?\s*(?:[+*/-]=|=(?!=)))"))
                            function.error = "Helper statements must be local arithmetic declarations or assignments.";
                }
                catch (NotSupportedException e) { function.error = e.Message; }
            }
            foreach (var group in functions.Values)
                foreach (var duplicates in group.GroupBy(f => f.Signature).Where(g => g.Count() > 1))
                    foreach (var function in duplicates)
                        function.error = "Duplicate or precision-only helper overloads cannot be resolved from ASE numeric widths: " + function.Signature;
        }
        public bool Contains(string name) { return functions.ContainsKey(name); }
        public bool IsAdapted(string name) { List<HlslLocalFunction> group; return functions.TryGetValue(name, out group) && group.All(f => string.IsNullOrEmpty(f.error)); }
        public HlslLocalFunction Resolve(string name, string[] argumentTypes)
        {
            List<HlslLocalFunction> group;
            if (!functions.TryGetValue(name, out group)) throw new NotSupportedException("Unresolved helper: " + name);
            // An unrepresentable overload could win HLSL's selection. Do not silently drop it.
            var invalid = group.FirstOrDefault(f => !string.IsNullOrEmpty(f.error));
            if (invalid != null) throw new NotSupportedException(name + ": " + invalid.error);
            var matches = group.Where(f => f.parameterTypes.SequenceEqual(argumentTypes)).ToArray();
            if (matches.Length != 1) throw new NotSupportedException("Helper overload requires one exact scalar/vector width match; implicit conversions are not adapted: " + name + "(" + string.Join(",", argumentTypes) + ")");
            return matches[0];
        }
        internal static string Type(string declared) { char last = declared[declared.Length - 1]; return "FLOAT" + (last >= '2' && last <= '4' ? last.ToString() : ""); }
        internal static string[] Statements(string body)
        {
            if (body.TrimEnd().Length > 0 && !body.TrimEnd().EndsWith(";", StringComparison.Ordinal)) throw new NotSupportedException("A local statement is missing a semicolon.");
            return body.Split(';').Select(s => s.Trim()).Where(s => s.Length > 0).ToArray();
        }

        // This deliberately excludes counter reads, nested scopes and per-iteration declarations.
        // They need integer/scoping semantics. It covers small fixed octave/accumulator loops.
        internal static string ExpandBoundedLoops(string body)
        {
            int expanded = 0;
            while (Regex.IsMatch(body, @"\bfor\s*\("))
            {
                Match loop = Regex.Match(body, @"\bfor\s*\(\s*int\s+(?<id>\w+)\s*=\s*(?<start>\d+)\s*;\s*\k<id>\s*<\s*(?<end>\d+)\s*;\s*\k<id>\s*\+\+\s*\)\s*\{");
                if (!loop.Success || ++expanded > 8) throw new NotSupportedException("Loop control flow requires a bounded arithmetic accumulator: for (int k=N; k<M; k++). Maximum 16 iterations.");
                int start = 0, end = 0;
                if (!int.TryParse(loop.Groups["start"].Value, NumberStyles.None, CultureInfo.InvariantCulture, out start) || !int.TryParse(loop.Groups["end"].Value, NumberStyles.None, CultureInfo.InvariantCulture, out end) || end < start || (long)end - start > 16)
                    throw new NotSupportedException("Loop control flow exceeds the 16-iteration arithmetic expansion limit.");
                int open = body.IndexOf('{', loop.Index + loop.Length - 1), close = ShaderText.FindMatchingBrace(body, open);
                if (close < 0) throw new NotSupportedException("Unbalanced loop control flow.");
                string iteration = body.Substring(open + 1, close - open - 1);
                if (Regex.IsMatch(iteration, @"\b" + Regex.Escape(loop.Groups["id"].Value) + @"\b|[{}#?:]|\b(?:return|break|continue|discard|clip|if|else|for|while|do|switch|float[1-4]?|half[1-4]?|fixed[1-4]?|int|uint|bool|tex\w*|SAMPLE_\w*|UNITY_\w*)\b"))
                    throw new NotSupportedException("Loop control flow must not read its counter, declare scoped locals, sample textures or change control flow.");
                var repeated = new StringBuilder();
                for (int i = start; i < end; i++) repeated.Append(iteration).Append('\n');
                body = body.Substring(0, loop.Index) + repeated + body.Substring(close + 1);
                if (body.Length > 65536) throw new NotSupportedException("Expanded local program is too large.");
            }
            return body;
        }
    }
}
