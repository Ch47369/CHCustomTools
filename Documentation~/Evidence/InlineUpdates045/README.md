# Inline plugin updates (0.4.5)

The converter main window renders the current version, check action, status, and versioned install action directly. The install action appears only for a strictly newer discovered release. The old public ShaderPackageUpdateWindow.Open entry opens the same converter window. An old saved update-window instance redirects on the Editor update loop and closes itself.

Validation: 592 core checks; EditorCompile against Unity 2022.3.10f1 and 6000.0.80f1, both zero warnings/errors. The isolated Unity 2022.3 integration checks the exact Tools/Shader menu, repeated legacy entry calls, unknown/equal/newer release states, old-layout restoration and GUI Error/Exception/Assert capture. A fake future version is displayed only and never installed. Final tarball installation has its own report under Releases~.

Network evidence is recorded separately from UI success via privateGitCheckSucceeded and checkMessage. The initial attempt discovered real tag v0.4.4 but failed the old-layout check. The successful final source UI check experienced a Git query failure and verified that the error stays in the main window and offers no update. Backend Git discovery/installation code is unchanged; this release does not claim a completed online Git upgrade. All attempts remain in .build~/InlineUpdates045/Attempts. Only accepted UI reports are collected here.

Run Tools~/Run-InlineUpdates.ps1 (optionally -Tarballs), then Tools~/Verify-Release.py and Tools~/Verify-InlineUpdatesRelease.py. Runtime, 293 library artifacts, and unaffected Editor files are compared byte for byte against fixed 0.4.4. No conversion semantics or rendering claims are added.
