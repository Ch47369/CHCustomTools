using System;

namespace CH.CustomTools.VFX
{
    // Audio labels share the host's cached locale and never register another preference poller.
    internal static partial class CHToolLanguage
    {
        internal static bool IsChinese { get { return ASEShaderConverter.Editor.CHToolLanguage.IsChinese; } }
        internal static string Pick(string zh, string en) { return IsChinese ? zh : en; }
        internal static string Text(string value) { return Text(IsChinese, value); }
        internal static string Text(bool chinese, string value)
        {
            string english;
            return !chinese && value != null && English.TryGetValue(value, out english) ? english : value;
        }
        internal static string[] Text(bool chinese, string[] values) { return Array.ConvertAll(values, value => Text(chinese, value)); }
        internal static string[] Text(string[] values) { return Array.ConvertAll(values, Text); }
    }
    internal sealed class CHToolMessage
    {
        readonly string zh, en;
        internal CHToolMessage(string zh, string en) { this.zh = zh; this.en = en; }
        public static implicit operator string(CHToolMessage value) { return value == null ? null : CHToolLanguage.Pick(value.zh, value.en); }
        public static implicit operator CHToolMessage(string value) { return new CHToolMessage(value, value); }
    }
}
