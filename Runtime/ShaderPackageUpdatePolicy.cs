using System;
using System.Linq;
using System.Text.RegularExpressions;

namespace ASEShaderConverter
{
    public sealed class ShaderPackageRelease
    {
        public string tag;
        public Version version;
    }

    // Pure policy shared by the editor updater and offline checks. No credentials or network.
    public static class ShaderPackageUpdatePolicy
    {
        public const string PackageName = "com.aseshader.handwritten-converter";
        public const string Repository = "https://github.com/Ch47369/CHCustomTools.git";
        public const string SshRepository = "ssh://git@github.com/Ch47369/CHCustomTools.git";
        public const string ReleasesUrl = "https://github.com/Ch47369/CHCustomTools/releases";
        const string Stable = @"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)";

        public static bool TryVersion(string value, out Version version)
        {
            version = null;
            return value != null && Regex.IsMatch(value, "^" + Stable + @"\z") && Version.TryParse(value, out version);
        }
        public static ShaderPackageRelease Latest(string remoteTags)
        {
            if (remoteTags == null || remoteTags.Length > 1024 * 1024) throw new ArgumentException("Invalid Git tag response.");
            ShaderPackageRelease latest = null;
            foreach (string line in remoteTags.Split('\n'))
            {
                var match = Regex.Match(line.Trim(), @"^[0-9a-fA-F]{40}(?:[0-9a-fA-F]{24})?\s+refs/tags/(?<tag>v(?<version>" + Stable + @"))$");
                Version version;
                if (!match.Success || !TryVersion(match.Groups["version"].Value, out version)) continue;
                if (latest == null || version > latest.version) latest = new ShaderPackageRelease { tag = match.Groups["tag"].Value, version = version };
            }
            return latest;
        }
        public static string InstalledRepository(string packageId)
        {
            string prefix = PackageName + "@";
            if (packageId == null || !packageId.StartsWith(prefix, StringComparison.Ordinal)) return null;
            string url = packageId.Substring(prefix.Length).Split('#')[0];
            return IsRepository(url) ? url : null;
        }
        public const string LegacyRepository = "https://github.com/Ch47369/ShaderConverter.git";
        public const string LegacySshRepository = "ssh://git@github.com/Ch47369/ShaderConverter.git";
        public static bool IsHttpsRepository(string url) { return url == Repository || url == LegacyRepository; }
        public static bool IsRepository(string url) { return IsHttpsRepository(url) || url == SshRepository || url == LegacySshRepository; }
        public static bool CanInstall(string installed, ShaderPackageRelease target, bool migrateLocal)
        {
            Version current;
            return TryVersion(installed, out current) && target != null && target.version != null && (target.version > current || (migrateLocal && target.version == current));
        }
        public static string InstallationUrl(string repository, string tag)
        {
            if (!IsRepository(repository) || tag == null || !Regex.IsMatch(tag, "^v" + Stable + @"\z")) throw new ArgumentException("Unsupported repository or version tag.");
            return repository + "#" + tag;
        }
    }
}
