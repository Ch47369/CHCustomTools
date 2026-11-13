# Author, menus, and built-in language selectors (0.4.3)

Final requested behavior: author CH; Shader commands under Tools/Shader; audio and resource organizer under Tools/VFX. Chinese / English controls are built into each main tool window. No separate language package, settings window, or top-level settings group. Default follows Unity, saved manual preference is shared.

Core: 592 checks. Shader EditorCompile against Unity 2022.3.10f1 and 6000.0.80f1: 0 warnings / 0 errors. Integration reports cover independent Shader installation and both packages together, actual menu invocation, window repaint in both languages, and restoration of the original language preference. Audio native pack and standalone install: 21 checks, including author, menus, audio authoring, export, resource moves/restore and unchanged installed-package bytes.

Only final successful reports are collected here. Preliminary attempts and the test harness compilation/UI log audit remain under .build~/ToolMenus043/Attempts; audio pack attempts remain in the audio development project's Artifacts/UnityTarball. Final tarball installation report is also delivered under Releases~. No conversion semantics or visual equivalence claims are added. All Runtime, library assets and unaffected Editor files are checked against the fixed 0.4.2 archive.
