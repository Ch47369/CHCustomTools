using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace ASEShaderConverter
{
    [Serializable] public sealed class GraphPresentationOptions
    {
        public bool autoLayout = true, addComments = true, useRegisters = true;
        public float longWireDistance = 1800;
        public int maxRegisters = 24;
    }
    [Serializable] public sealed class GraphCommentPlan
    {
        public string id = "", title = "", text = "";
    }
    public sealed class GraphLayoutItem
    {
        public string id, group;
        public float x, y, width = 260, height = 260;
    }
    public static class GraphExplanation
    {
        public static string ForExpression(string expression)
        {
            string value = Regex.Replace(expression, @"\s+", " ").Trim();
            var notes = new List<string>();
            if (value.Contains("tex2Dlod") || value.Contains("TEX2DARRAY_LOD")) notes.Add("以显式 LOD 读取纹理");
            else if (value.Contains("tex2D(")) notes.Add("按 UV 采样纹理");
            if (value.Contains("lerp(")) notes.Add("按权重混合两个结果");
            if (value.Contains("step(")) notes.Add("用阈值产生 0/1 选择信号");
            if (value.Contains("floor(")) notes.Add("向下取整定位网格单元");
            if (value.Contains("round(")) notes.Add("取最近整数作为索引");
            if (value.Contains("clamp(")) notes.Add("限制数值范围");
            if (value.Contains("frac(")) notes.Add("取小数部分使坐标循环");
            return (notes.Count == 0 ? "按连线计算并传递结果" : string.Join("；", notes.Take(3).ToArray())) + "。表达式：" + (value.Length > 90 ? value.Substring(0, 87) + "..." : value);
        }
    }

    // Deterministic block layering. Groups cannot overlap, and all dependency edges advance.
    // Coordinates and sizes are plain numbers so this algorithm can be checked outside Unity.
    public static class ShaderGraphLayout
    {
        private sealed class Block
        {
            public string id;
            public List<GraphLayoutItem> nodes;
            public int rank;
            public float width, height, x, y;
        }
        public static void Arrange(IList<GraphLayoutItem> items, IList<ShaderWirePlan> edges)
        {
            var byId = items.ToDictionary(n => n.id);
            var blocks = items.GroupBy(n => string.IsNullOrEmpty(n.group) ? "ungrouped" : n.group)
                .Select(g => new Block { id = g.Key, nodes = g.ToList() }).ToList();
            var groupByNode = blocks.SelectMany(b => b.nodes.Select(n => new { n.id, block = b })).ToDictionary(p => p.id, p => p.block);
            var validEdges = edges.Where(e => byId.ContainsKey(e.from) && byId.ContainsKey(e.to)).ToList();
            var ordered = Sort(items.Select(n => n.id), validEdges);
            // Rank the contracted group graph, not whichever member node happens to be
            // ready first. A group can contain constants and a much later computed result;
            // processing its early outgoing edge before all its inputs produced false cycles.
            var groupEdges = validEdges.Where(e => groupByNode[e.from] != groupByNode[e.to])
                .Select(e => new ShaderWirePlan { from = groupByNode[e.from].id, to = groupByNode[e.to].id })
                .GroupBy(e => e.from + "\n" + e.to).Select(g => g.First()).ToList();
            List<string> groupOrder;
            try { groupOrder = Sort(blocks.Select(b => b.id), groupEdges); }
            catch (ArgumentException)
            {
                // Only a real group re-entry requires splitting an authored frame.
                foreach (var item in items) item.group = "node_" + item.id;
                Arrange(items, edges); return;
            }
            var byGroup = blocks.ToDictionary(b => b.id);
            foreach (string id in groupOrder)
            {
                foreach (var edge in groupEdges.Where(e => e.to == id))
                    byGroup[id].rank = Math.Max(byGroup[id].rank, byGroup[edge.from].rank + 1);
            }
            foreach (var block in blocks)
            {
                var rank = block.nodes.ToDictionary(n => n.id, n => 0);
                foreach (string id in ordered.Where(rank.ContainsKey))
                    foreach (var edge in validEdges.Where(e => e.to == id && rank.ContainsKey(e.from))) rank[id] = Math.Max(rank[id], rank[edge.from] + 1);
                // Keep constants and short branches next to their consumers instead of
                // stacking every source in a tall first column with long horizontal wires.
                foreach (string id in ordered.Where(rank.ContainsKey).Reverse())
                {
                    var consumers = validEdges.Where(e => e.from == id && rank.ContainsKey(e.to)).Select(e => rank[e.to] - 1).ToArray();
                    if (consumers.Length > 0) rank[id] = Math.Max(rank[id], consumers.Min());
                }
                float x = 50;
                foreach (var column in block.nodes.GroupBy(n => rank[n.id]).OrderBy(g => g.Key))
                {
                    float y = 115;
                    foreach (var item in column.OrderBy(n => NodeBarycenter(n.id, validEdges, byId)))
                    {
                        item.x = x; item.y = y;
                        y += item.height + 65;
                    }
                    x += column.Max(n => n.width) + 100;
                    block.height = Math.Max(block.height, y);
                }
                block.width = Math.Max(640, x - 50);
            }
            float blockX = 0;
            foreach (var layer in blocks.GroupBy(b => b.rank).OrderBy(g => g.Key))
            {
                float blockY = 0;
                foreach (var block in layer.OrderBy(b => Barycenter(b, validEdges, groupByNode)))
                {
                    block.x = blockX; block.y = blockY;
                    foreach (var item in block.nodes) { item.x += blockX; item.y += blockY; }
                    blockY += block.height + 130;
                }
                blockX += layer.Max(b => b.width) + 220;
            }
        }
        private static float Barycenter(Block block, List<ShaderWirePlan> edges, Dictionary<string, Block> byNode)
        {
            var inputs = edges.Where(e => byNode[e.to] == block && byNode[e.from] != block).Select(e => byNode[e.from].y).ToArray();
            return inputs.Length == 0 ? 0 : inputs.Average();
        }
        private static float NodeBarycenter(string id, List<ShaderWirePlan> edges, Dictionary<string, GraphLayoutItem> byId)
        {
            var inputs = edges.Where(e => e.to == id).Select(e => byId[e.from].y).ToArray();
            return inputs.Length == 0 ? 0 : inputs.Average();
        }
        private static List<string> Sort(IEnumerable<string> ids, List<ShaderWirePlan> edges)
        {
            var remaining = ids.ToList(); var result = new List<string>(); var done = new HashSet<string>();
            while (remaining.Count > 0)
            {
                var ready = remaining.Where(id => edges.All(e => e.to != id || done.Contains(e.from))).ToArray();
                if (ready.Length == 0) throw new ArgumentException("Graph layout requires an acyclic graph, including local variable references.");
                foreach (string id in ready) { done.Add(id); result.Add(id); remaining.Remove(id); }
            }
            return result;
        }
    }
}
