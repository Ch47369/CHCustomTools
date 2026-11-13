using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools.VFX
{
    // The persisted pattern stays compatible with existing presets and the naming engine.
    internal static class VfxNameBuilder
    {
        internal enum Kind { Prefix, Effect, Original, Index, Text }
        internal sealed class Part { public Kind kind; public string text="", after=""; public int digits=3; }
        static readonly Regex Tokens=new Regex(@"\{prefix\}|\{effect\}|\{name\}|\{index(?::0{1,8})?\}");
        static string T(string zh,string en) { return CHToolLanguage.Pick(zh,en); }
        internal static bool TryParse(string pattern,out List<Part> parts)
        {
            parts=new List<Part>();int cursor=0;
            foreach(Match match in Tokens.Matches(pattern??""))
            {
                string literal=pattern.Substring(cursor,match.Index-cursor);
                if(literal.IndexOfAny(new[]{'{','}'})>=0)return false;
                if(parts.Count==0 && literal.Length>0)parts.Add(new Part{kind=Kind.Text,text=literal});
                else if(parts.Count>0)parts[parts.Count-1].after=literal;
                var part=new Part{kind=match.Value=="{prefix}"?Kind.Prefix:match.Value=="{effect}"?Kind.Effect:match.Value=="{name}"?Kind.Original:Kind.Index};
                if(part.kind==Kind.Index)part.digits=match.Value=="{index}"?1:match.Value.Length-8;
                parts.Add(part);cursor=match.Index+match.Length;
            }
            string tail=(pattern??"").Substring(cursor);
            if(tail.IndexOfAny(new[]{'{','}'})>=0)return false;
            if(parts.Count==0)parts.Add(new Part{kind=Kind.Text,text=tail});else parts[parts.Count-1].after=tail;
            return true;
        }
        internal static string Compose(List<Part> parts)
        {
            var result=new StringBuilder();
            foreach(var part in parts)
            {
                switch(part.kind)
                {
                    case Kind.Prefix:result.Append("{prefix}");break;
                    case Kind.Effect:result.Append("{effect}");break;
                    case Kind.Original:result.Append("{name}");break;
                    case Kind.Index:result.Append("{index:").Append(new string('0',Mathf.Clamp(part.digits,1,8))).Append('}');break;
                    default:result.Append(part.text);break;
                }
                result.Append(part.after);
            }
            return result.ToString();
        }
        internal static void Draw(VfxResourceRule rule)
        {
            List<Part> parts;
            if(!TryParse(rule.pattern,out parts))
            {
                EditorGUILayout.HelpBox(T("旧命名方案包含无法识别的内容，已保留。点击下方按钮可重新设置组合。","The existing naming scheme contains unsupported content and is preserved. Use the button below to start a new combination."),MessageType.Warning);
                if(GUILayout.Button(T("重新设置命名组合","Start a new naming combination"))) {rule.pattern="{prefix}_{effect}_{index:000}";GUI.changed=true;}
                return;
            }
            EditorGUILayout.LabelField(T("按下面的顺序组成文件名，可上下移动片段。连接文字可填 _、- 或留空。","The filename follows the order below. Move parts up or down; joining text can be _, - or empty."),EditorStyles.wordWrappedMiniLabel);
            string[] names={T("文件名前缀","Prefix"),T("特效名","Effect name"),T("原文件名","Original name"),T("序号","Number"),T("自定义文字","Custom text")};
            EditorGUI.BeginChangeCheck();int remove=-1,move=-1,direction=0;
            for(int i=0;i<parts.Count;i++)
            {
                var part=parts[i];
                using(new EditorGUILayout.HorizontalScope())
                {
                    GUILayout.Label((i+1).ToString(),GUILayout.Width(18));
                    part.kind=(Kind)EditorGUILayout.Popup((int)part.kind,names,GUILayout.Width(110));
                    if(part.kind==Kind.Text)part.text=EditorGUILayout.TextField(part.text,GUILayout.MinWidth(40));
                    else if(part.kind==Kind.Index)
                    {
                        string[] formats={"1, 2, 3","01, 02, 03","001, 002, 003","0001, 0002, 0003","00001…","000001…","0000001…","00000001…"};
                        part.digits=1+EditorGUILayout.Popup(part.digits-1,formats,GUILayout.MinWidth(65));
                    }
                    else GUILayout.Label(part.kind==Kind.Prefix?rule.prefix:part.kind==Kind.Effect?T("使用上方特效名","Uses effect name above"):T("使用资源原名","Uses asset's original name"),EditorStyles.miniLabel,GUILayout.MinWidth(40));
                    GUILayout.Label(T("连接文字","Join with"),GUILayout.Width(CHToolLanguage.IsChinese?54:62));
                    part.after=EditorGUILayout.TextField(part.after,GUILayout.Width(48));
                    using(new EditorGUI.DisabledScope(i==0))if(GUILayout.Button(new GUIContent("↑",T("上移","Move up")),GUILayout.Width(24))){move=i;direction=-1;}
                    using(new EditorGUI.DisabledScope(i==parts.Count-1))if(GUILayout.Button(new GUIContent("↓",T("下移","Move down")),GUILayout.Width(24))){move=i;direction=1;}
                    if(GUILayout.Button(new GUIContent("×",T("删除片段","Remove part")),GUILayout.Width(24)))remove=i;
                }
            }
            bool edited=EditorGUI.EndChangeCheck();
            if(remove>=0){parts.RemoveAt(remove);edited=true;}
            if(move>=0){var part=parts[move];parts.RemoveAt(move);parts.Insert(move+direction,part);edited=true;}
            if(GUILayout.Button(T("＋ 添加命名片段","＋ Add filename part")))
            {
                if(parts.Count>0 && parts[parts.Count-1].after.Length==0)parts[parts.Count-1].after="_";
                parts.Add(new Part{kind=Kind.Original});edited=true;
            }
            if(edited){rule.pattern=Compose(parts);GUI.changed=true;}
        }
    }
}
