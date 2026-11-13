using System;
using System.Collections.Generic;
namespace ASEShaderConverter
{
    internal enum ExprTokenKind { End, Identifier, Number, Operator, Open, Close, Comma, Dot }

    internal struct ExprToken
    {
        public ExprTokenKind Kind;
        public string Text;
        public ExprToken(ExprTokenKind kind, string text) { Kind = kind; Text = text; }
    }

    internal abstract class HlslExpr
    {
        public string Original = string.Empty;
    }

    internal sealed class NumberExpr : HlslExpr { public string Value; public bool IntegerLiteral; }
    internal sealed class IdentifierExpr : HlslExpr { public string Name; }
    internal sealed class UnaryExpr : HlslExpr { public string Op; public HlslExpr Value; }
    internal sealed class BinaryExpr : HlslExpr { public string Op; public HlslExpr Left; public HlslExpr Right; }
    internal sealed class CallExpr : HlslExpr { public string Name; public readonly List<HlslExpr> Arguments = new List<HlslExpr>(); }
    internal sealed class MemberExpr : HlslExpr { public HlslExpr Target; public string Name; }
    internal sealed class ConditionalExpr : HlslExpr { public HlslExpr Condition, Yes, No; }
    internal sealed class CastExpr : HlslExpr { public string Type; public HlslExpr Value; }

    internal sealed class ExpressionParser
    {
        private readonly List<ExprToken> tokens = new List<ExprToken>();
        private int index;
        private int depth;

        private ExpressionParser(string source)
        {
            if (source.Length > 65536) throw new NotSupportedException("Expression is too large.");
            Tokenize(source);
        }

        public static HlslExpr TryParse(string source)
        {
            if (string.IsNullOrEmpty(source)) return null;
            try
            {
                ExpressionParser p = new ExpressionParser(source);
                HlslExpr expression = p.ParseExpression(0);
                if (expression == null || p.Peek().Kind != ExprTokenKind.End) return null;
                expression.Original = source.Trim();
                return expression;
            }
            catch { return null; }
        }

        private void Tokenize(string source)
        {
            int i = 0;
            while (i < source.Length)
            {
                char c = source[i];
                if (char.IsWhiteSpace(c)) { i++; continue; }
                if (char.IsLetter(c) || c == '_')
                {
                    int start = i++;
                    while (i < source.Length && (char.IsLetterOrDigit(source[i]) || source[i] == '_')) i++;
                    tokens.Add(new ExprToken(ExprTokenKind.Identifier, source.Substring(start, i - start)));
                    continue;
                }
                if (char.IsDigit(c) || (c == '.' && i + 1 < source.Length && char.IsDigit(source[i + 1])))
                {
                    int start = i++;
                    while (i < source.Length && (char.IsDigit(source[i]) || source[i] == '.' || source[i] == 'e' || source[i] == 'E' || source[i] == '+' || source[i] == '-'))
                    {
                        char n = source[i];
                        if ((n == '+' || n == '-') && source[i - 1] != 'e' && source[i - 1] != 'E') break;
                        i++;
                    }
                    while (i < source.Length && (source[i] == 'f' || source[i] == 'h')) i++;
                    tokens.Add(new ExprToken(ExprTokenKind.Number, source.Substring(start, i - start)));
                    continue;
                }
                if (c == '(') { tokens.Add(new ExprToken(ExprTokenKind.Open, "(")); i++; continue; }
                if (c == ')') { tokens.Add(new ExprToken(ExprTokenKind.Close, ")")); i++; continue; }
                if (c == ',') { tokens.Add(new ExprToken(ExprTokenKind.Comma, ",")); i++; continue; }
                if (c == '.') { tokens.Add(new ExprToken(ExprTokenKind.Dot, ".")); i++; continue; }
                string two = i + 1 < source.Length ? source.Substring(i, 2) : string.Empty;
                if (two == "<=" || two == ">=" || two == "==" || two == "!=" || two == "&&" || two == "||")
                {
                    tokens.Add(new ExprToken(ExprTokenKind.Operator, two)); i += 2; continue;
                }
                if ("+-*/%<>!".IndexOf(c) >= 0)
                {
                    tokens.Add(new ExprToken(ExprTokenKind.Operator, c.ToString())); i++; continue;
                }
                // Brackets, semicolons and macros remain outside the supported expression grammar.
                tokens.Add(new ExprToken(ExprTokenKind.Operator, c.ToString())); i++;
            }
            tokens.Add(new ExprToken(ExprTokenKind.End, string.Empty));
        }

        private ExprToken Peek() { return tokens[Math.Min(index, tokens.Count - 1)]; }
        private ExprToken Consume() { return tokens[Math.Min(index++, tokens.Count - 1)]; }

        private HlslExpr ParseExpression(int minimumPrecedence)
        {
            if (++depth > 128) throw new NotSupportedException("Expression nesting is too deep.");
            try { return ParseExpressionCore(minimumPrecedence); }
            finally { depth--; }
        }
        private HlslExpr ParseExpressionCore(int minimumPrecedence)
        {
            HlslExpr left = ParsePrefix();
            if (left == null) return null;
            while (Peek().Kind == ExprTokenKind.Operator)
            {
                string op = Peek().Text;
                if (op == "?" && minimumPrecedence == 0)
                {
                    Consume();
                    HlslExpr yes = ParseExpression(0);
                    if (yes == null || Consume().Text != ":") return null;
                    HlslExpr no = ParseExpression(0);
                    if (no == null) return null;
                    left = new ConditionalExpr { Condition = left, Yes = yes, No = no };
                    continue;
                }
                int precedence = Precedence(op);
                if (precedence < minimumPrecedence) break;
                Consume();
                HlslExpr right = ParseExpression(precedence + 1);
                if (right == null) return null;
                left = new BinaryExpr { Op = op, Left = left, Right = right, Original = left.Original + op + right.Original };
            }
            return left;
        }

        private HlslExpr ParsePrefix()
        {
            if (++depth > 128) throw new NotSupportedException("Expression nesting is too deep.");
            try { return ParsePrefixCore(); }
            finally { depth--; }
        }
        private HlslExpr ParsePrefixCore()
        {
            ExprToken token = Peek();
            if (token.Kind == ExprTokenKind.Operator && (token.Text == "-" || token.Text == "!" || token.Text == "+"))
            {
                Consume();
                HlslExpr value = ParsePrefix();
                return value == null ? null : new UnaryExpr { Op = token.Text, Value = value, Original = token.Text + value.Original };
            }
            if (token.Kind == ExprTokenKind.Number)
            {
                Consume();
                return new NumberExpr { Value = token.Text.TrimEnd('f', 'h'), IntegerLiteral = System.Text.RegularExpressions.Regex.IsMatch(token.Text, @"^\d+$"), Original = token.Text };
            }
            if (token.Kind == ExprTokenKind.Identifier)
            {
                Consume();
                HlslExpr result = new IdentifierExpr { Name = token.Text, Original = token.Text };
                if (Peek().Kind == ExprTokenKind.Open)
                {
                    Consume();
                    CallExpr call = new CallExpr { Name = token.Text, Original = token.Text };
                    if (Peek().Kind != ExprTokenKind.Close)
                    {
                        while (true)
                        {
                            HlslExpr argument = ParseExpression(0);
                            if (argument == null) return null;
                            call.Arguments.Add(argument);
                            if (Peek().Kind != ExprTokenKind.Comma) break;
                            Consume();
                        }
                    }
                    if (Peek().Kind != ExprTokenKind.Close) return null;
                    Consume();
                    call.Original = token.Text;
                    result = call;
                }
                while (Peek().Kind == ExprTokenKind.Dot)
                {
                    Consume();
                    ExprToken member = Consume();
                    if (member.Kind != ExprTokenKind.Identifier) return null;
                    result = new MemberExpr { Target = result, Name = member.Text, Original = result.Original + "." + member.Text };
                }
                return result;
            }
            if (token.Kind == ExprTokenKind.Open)
            {
                Consume();
                if (Peek().Kind == ExprTokenKind.Identifier && System.Text.RegularExpressions.Regex.IsMatch(Peek().Text, @"^(?:float|half|fixed)[1-4]?$") && index + 1 < tokens.Count && tokens[index + 1].Kind == ExprTokenKind.Close)
                {
                    string type = Consume().Text; Consume();
                    HlslExpr value = ParsePrefix();
                    return value == null ? null : new CastExpr { Type = type, Value = value };
                }
                HlslExpr inner = ParseExpression(0);
                if (Peek().Kind != ExprTokenKind.Close) return null;
                Consume();
                while (Peek().Kind == ExprTokenKind.Dot)
                {
                    Consume(); ExprToken member = Consume();
                    if (member.Kind != ExprTokenKind.Identifier) return null;
                    inner = new MemberExpr { Target = inner, Name = member.Text, Original = inner.Original + "." + member.Text };
                }
                return inner;
            }
            return null;
        }

        private static int Precedence(string op)
        {
            switch (op)
            {
                case "||": return 1;
                case "&&": return 2;
                case "==": case "!=": return 3;
                case "<": case ">": case "<=": case ">=": return 4;
                case "+": case "-": return 5;
                case "*": case "/": case "%": return 6;
                default: return -1;
            }
        }
    }

}
