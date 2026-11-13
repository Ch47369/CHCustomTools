using System;
using System.IO;
using System.Threading;
using ASEShaderConverter.Editor;

internal static class ShaderGitClientChecks
{
    public static int Run()
    {
        int count = 0;
        Action<bool, string> check = (ok, name) => { if (!ok) throw new Exception(name); count++; };
        check(ShaderGitClient.Classify("No git executable was found. Please install Git.") == ShaderGitFailure.GitUnavailable, "UPM missing-Git failures are distinct from authentication");
        check(ShaderGitClient.Classify("fatal: could not read Username: terminal prompts disabled") == ShaderGitFailure.Authentication, "Missing credentials are identified as authentication");
        check(ShaderGitClient.Classify("remote: Repository not found.") == ShaderGitFailure.AccessDenied, "Private repository denial is distinct from a missing Git installation");
        check(ShaderGitClient.Classify("Permission denied (publickey).") == ShaderGitFailure.AccessDenied, "SSH key denial is a repository access issue");
        foreach (string error in new[] { "Failed to connect to github.com port 443", "Could not resolve host: github.com", "Could not resolve proxy: private-proxy", "SSL certificate problem", "HTTP/2 stream was not closed cleanly", "The requested URL returned error: 503" })
            check(ShaderGitClient.Classify(error) == ShaderGitFailure.Network, "Transport failure is identified without asking for authentication");
        check(ShaderGitClient.Classify("operation timed out") == ShaderGitFailure.Timeout, "Timeout has a separate diagnostic");
        check(ShaderGitClient.Classify("unrecognized local configuration") == ShaderGitFailure.Unknown, "Unknown failures do not invent a cause");
        string folder = Path.Combine(Directory.GetCurrentDirectory(), ".build~", "GitClientChecks-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(folder);
        string git = Path.Combine(folder, "git.exe");
        try
        {
            File.WriteAllText(git, "discovery-only fixture; never execute");
            check(ShaderGitClient.FindGit("\"" + folder + "\"", new string[0], true) == git, "Quoted Git PATH directories are supported");
            check(ShaderGitClient.FindGit("", new[] { git }, true) == git, "Installed Git can be found when the Editor PATH is stale");
            check(ShaderGitClient.FindGit("", new[] { Path.Combine(folder, "missing.exe") }, true) == null, "A missing executable is reported as missing");
        }
        finally { File.Delete(git); Directory.Delete(folder); }
        bool rejected = false;
        try { ShaderGitClient.ReadTags("https://untrusted.example/repo.git", false, CancellationToken.None).GetAwaiter().GetResult(); }
        catch (ArgumentException) { rejected = true; }
        check(rejected, "Only the fixed repository allowlist can reach Git");
        check(new ShaderGitCheckException(ShaderGitFailure.Authentication).ToString().IndexOf("token", StringComparison.OrdinalIgnoreCase) < 0, "Git exceptions contain only a safe category");
        return count;
    }
}
