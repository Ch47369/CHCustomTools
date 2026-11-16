# 0.6.4 Scene tools evidence

The source fixture matrix has 240 checks across Unity 2022.3.10f1 and 6000.0.80f1, Windows D3D11. Core checks: 629. Editor compilation: zero warnings and errors in both versions. Final Tarball installation results are recorded separately in Releases~/scene-tools-tarball-install-0.6.4.json.

- UnitySceneToolsSmoke: explicit Scene activation, default/custom shortcuts, exclusivity, persistence, independent Bezier corners, actual tangent dragging, Undo, gesture cancellation and host cleanup.
- UnityPathVisibilitySmoke: actual rendered curve pixels between points, Gizmos on/off, projection, generated-child selection, occlusion and unselected paths. before-063.png is the published baseline; after-064.png is the corrected Scene curve.
- UnityPathPreviewSmoke: preview creates no objects/assets or source behaviour callbacks, preserves committed geometry until Generate, matches final mesh positions/normals/UV0/UV1/triangles and placed model matrices, updates point tilt and Undo/Redo, handles invalid settings and cleans up. live-preview images are rendered from the actual Scene camera using its normal preview callbacks, while committed renderers are disabled in the fixture so they cannot produce a false positive. Red shapes are placed models and the green strip is the temporary mesh. The render fixture uses Built-in Unlit/Color; this is not a cross-pipeline material-equivalence test.

A clean package snapshot starts from v0.6.3 and overlays only the Scene changes, excluding concurrent Backend/SidebarLine work. Fixed baseline Tarball SHA256: 13a0eafeafd588556a05af318d5cdf9acf5ae2036ba0bb944513d2b0d8f049d0. Runtime schema, all runtime files, 293 shader graphs, audio/VFX algorithms and updater remain byte-identical. Point tilt uses the existing roll field and does not automatically conform an entire curve to terrain.

Failed attempts remain in .build~/SceneTools064/Attempts and .build~/PathPreview064/Attempts, including the initial lifecycle/Undo regressions and black intermediate GUI render-target captures. Scene-camera readback is used for authoring preview verification. User projects are not modified.
