using System;
using ASEShaderConverter;

internal static class PackageUpdateChecks
{
    public static int Run()
    {
        int count = 0;
        Action<bool,string> check = (ok,name) => { if (!ok) throw new Exception(name); count++; };
        string hash = new string('a',40);
        var latest = ShaderPackageUpdatePolicy.Latest(hash+"\trefs/tags/v0.4.9\n"+hash+"\trefs/tags/v0.4.10\n"+hash+"\trefs/tags/v2.0.0-preview.1\n"+hash+"\trefs/heads/v9.0.0\n"+hash+"\trefs/tags/v8.0.0^{}\n");
        check(latest.tag=="v0.4.10","Stable versions compare numerically and ignore prereleases/branches/peeled tags");
        check(ShaderPackageUpdatePolicy.Latest("unauthorized")==null,"Authentication diagnostics are not treated as a version");
        Version version;
        foreach (string invalid in new[]{"01.0.0","1.0","1.0.0-preview","1.0.0+build","999999999999.0.0","1.2.3\n"}) check(!ShaderPackageUpdatePolicy.TryVersion(invalid,out version),"Reject unsupported version: "+invalid);
        check(ShaderPackageUpdatePolicy.CanInstall("0.4.0",latest,false),"New stable version updates an installed Git package");
        check(!ShaderPackageUpdatePolicy.CanInstall("0.4.10",latest,false),"Same Git version does not update");
        check(!ShaderPackageUpdatePolicy.CanInstall("0.5.0",latest,true),"A migration cannot downgrade");
        check(ShaderPackageUpdatePolicy.CanInstall("0.4.10",latest,true),"Local installation can migrate at the same version");
        check(!ShaderPackageUpdatePolicy.CanInstall("broken",latest,true),"Unknown installed version is blocked");
        foreach (string repository in new[]{ShaderPackageUpdatePolicy.Repository,ShaderPackageUpdatePolicy.SshRepository})
        {
            check(ShaderPackageUpdatePolicy.InstalledRepository(ShaderPackageUpdatePolicy.PackageName+"@"+repository+"#v0.4.0")==repository,"Preserve installed HTTPS or SSH transport");
            check(ShaderPackageUpdatePolicy.InstallationUrl(repository,latest.tag)==repository+"#v0.4.10","Update remains pinned to the chosen tag");
        }
        foreach (string repository in new[]{"https://github.com/Someone/Fork.git","https://token@github.com/Ch47369/ShaderConverter.git",ShaderPackageUpdatePolicy.Repository+"?path=/Other","file:F:/ASEShader"})
            check(ShaderPackageUpdatePolicy.InstalledRepository(ShaderPackageUpdatePolicy.PackageName+"@"+repository)==null,"Foreign/credential-bearing/subdirectory Git URL is not silently rewritten");
        bool rejected = false; try { ShaderPackageUpdatePolicy.InstallationUrl(ShaderPackageUpdatePolicy.Repository,"v0.5.0\" --upload-pack=evil"); } catch (ArgumentException) { rejected=true; }
        check(rejected,"Untrusted version cannot become a Git argument");
        return count;
    }
}
