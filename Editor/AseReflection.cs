using System;
using System.Collections;
using System.Globalization;
using System.Linq;
using System.Reflection;
using System.Runtime.ExceptionServices;

namespace ASEShaderConverter.Editor
{
    // No compile-time reference to ASE: it may be in an asmdef or Assembly-CSharp-Editor.
    internal static class AseReflection
    {
        private const BindingFlags Public = BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static;

        public static Type Find(string name, bool required = true)
        {
            string full = name.StartsWith("AmplifyShaderEditor.", StringComparison.Ordinal) ? name : "AmplifyShaderEditor." + name;
            foreach (var assembly in AppDomain.CurrentDomain.GetAssemblies())
            {
                Type type = assembly.GetType(full, false);
                if (type != null) return type;
            }
            if (required) throw new NotSupportedException("ASE type is not installed/loaded: " + full);
            return null;
        }

        public static object Get(object target, string name)
        {
            Type type = target as Type ?? target.GetType();
            object instance = target is Type ? null : target;
            var property = type.GetProperty(name, Public);
            if (property != null) return property.GetValue(instance, null);
            var field = type.GetField(name, Public);
            if (field != null) return field.GetValue(instance);
            throw new MissingMemberException(type.FullName, name);
        }

        public static void Set(object target, string name, object value)
        {
            Type type = target as Type ?? target.GetType();
            object instance = target is Type ? null : target;
            var property = type.GetProperty(name, Public);
            if (property != null && property.CanWrite) { property.SetValue(instance, ConvertValue(value, property.PropertyType), null); return; }
            var field = type.GetField(name, Public);
            if (field != null) { field.SetValue(instance, ConvertValue(value, field.FieldType)); return; }
            throw new MissingMemberException(type.FullName, name);
        }

        public static object Call(object target, string name, params object[] args)
        {
            Type type = target as Type ?? target.GetType();
            foreach (var method in type.GetMethods(Public).Where(m => m.Name == name))
            {
                var parameters = method.GetParameters();
                if (args.Length > parameters.Length || parameters.Skip(args.Length).Any(p => !p.IsOptional)) continue;
                var actual = new object[parameters.Length]; bool match = true;
                for (int i = 0; i < parameters.Length; i++)
                {
                    if (i >= args.Length) { actual[i] = parameters[i].DefaultValue; continue; }
                    if (args[i] != null && !parameters[i].ParameterType.IsInstanceOfType(args[i])) { match = false; break; }
                    actual[i] = args[i];
                }
                if (!match) continue;
                try { return method.Invoke(target is Type ? null : target, actual); }
                catch (TargetInvocationException e) { ExceptionDispatchInfo.Capture(e.InnerException ?? e).Throw(); throw; }
            }
            throw new MissingMethodException(type.FullName, name + " (compatible public overload)");
        }

        public static object ConvertValue(object value, Type type)
        {
            if (type.IsInstanceOfType(value)) return value;
            if (type.IsEnum) return Enum.Parse(type, value.ToString(), false);
            return Convert.ChangeType(value, type, CultureInfo.InvariantCulture);
        }

        public static object[] Items(object collection) { return ((IEnumerable)collection).Cast<object>().ToArray(); }
        public static int Id(object node) { return (int)Get(node, "UniqueId"); }
        public static object WireType(string type) { return Enum.Parse(Find("WirePortDataType"), type == "FLOAT1" ? "FLOAT" : type, false); }
    }
}
