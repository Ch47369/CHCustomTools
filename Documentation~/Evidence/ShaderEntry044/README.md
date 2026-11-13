# Direct Tools/Shader entry (0.4.4)

The only top Tools command owned by ShaderConverter is Tools/Shader. Clicking it directly opens the converter window; library, package updates, and Agent inbox are available from the main window. Existing public Open methods remain available. Author CH and the built-in language selector are preserved.

Validation: 592 core checks; EditorCompile against Unity 2022.3.10f1 with zero warnings/errors; native ExecuteMenuItem("Tools/Shader") in an isolated editor, exact command registration and Chinese/English window repaint, with Error/Exception/Assert capture. Final tarball install report is delivered separately under Releases~. Runtime, library assets, and unaffected Editor files are checked against the fixed 0.4.3 archive. No conversion semantics or visual-equivalence claims are added.

Run Tools~/Run-ShaderEntry.ps1 (optionally -Tarballs), then Tools~/Verify-Release.py and Tools~/Verify-ShaderEntryRelease.py. Attempts and logs remain in .build~/ShaderEntry044/Attempts. Existing 0.4.3 packages and evidence are preserved.
