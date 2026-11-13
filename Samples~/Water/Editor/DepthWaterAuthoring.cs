using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using Object = UnityEngine.Object;

namespace ASEShaderWater.Editor
{
    // Original demo assets; does not load, switch, or save the user's open scenes.
    [InitializeOnLoad]
    public static class DepthWaterAuthoring
    {
        private const string Folder = "Assets/Shaders/DeepWater";
        private const string ShaderPath = "Assets/Shaders/DeepWater_ASE.shader";
        private const string Jobs = "Library/ASEShaderConverter/WaterDelivery";
        private static double nextPoll;

        [Serializable] private sealed class Job { public string id = "", action = "", shaderPath = ""; }
        [Serializable] private sealed class VariantCheck
        {
            public string name, preview;
            public string[] keywords;
            public bool compiled;
            public int changedPixels;
            public float meanAbsoluteDifference;
        }
        [Serializable] private sealed class Result
        {
            public bool success, compiled;
            public string error, shader, material, prefab, preview, graphicsApi, mainPass;
            public int shaderPasses, mainPassIndex, vertices, triangles, propertyCount;
            public string[] compilerMessages;
            public string[] materialKeywords;
            public VariantCheck[] variants;
        }

        private static readonly string[] Features = { "WAVES", "RIPPLES", "FRESNEL", "DEPTH", "FOAM", "CAUSTICS", "SCATTER", "REFRACTION" };

        static DepthWaterAuthoring() { EditorApplication.update += Poll; }

        private static void Poll()
        {
            if (EditorApplication.timeSinceStartup < nextPoll) return;
            nextPoll = EditorApplication.timeSinceStartup + 1;
            if (EditorApplication.isCompiling || EditorApplication.isUpdating || EditorApplication.isPlayingOrWillChangePlaymode) return;
            string path = Jobs + "/request.json";
            if (!File.Exists(path)) return;
            Job job = JsonUtility.FromJson<Job>(File.ReadAllText(path));
            if (job == null || !Guid.TryParse(job.id, out _) || !new[] {"create","preview","open","validate"}.Contains(job.action)) return;
            string claimed = Jobs + "/" + job.id + ".processing";
            File.Move(path, claimed);
            Result result;
            try
            {
                string target = string.IsNullOrEmpty(job.shaderPath) ? ShaderPath : job.shaderPath;
                if (target != ShaderPath && (!target.StartsWith(Folder + "/DeepWater_Caustics_",StringComparison.Ordinal) || !target.EndsWith(".shader",StringComparison.Ordinal)))
                    throw new ArgumentException("Only the delivered water or its review candidates can be checked.");
                result = job.action == "create" ? CreateAssets() : job.action == "open" ? OpenGraph(target) : job.action == "validate" ? ValidateVariants(target) : RenderPreview(target);
            }
            catch (Exception e) { result = new Result { success = false, error = e.ToString() }; Debug.LogException(e); }
            File.WriteAllText(Jobs + "/" + job.id + ".json", JsonUtility.ToJson(result, true));
            File.Move(claimed, claimed + ".done");
        }

        [MenuItem("Tools/ASE Shader Converter/Water/Create supporting assets")]
        public static void CreateFromMenu() { CreateAssets(); }

        [MenuItem("Tools/ASE Shader Converter/Water/Render water preview")]
        public static void PreviewFromMenu() { RenderPreview(); }

        [MenuItem("Tools/ASE Shader Converter/Water/Open water graph")]
        public static void OpenFromMenu() { OpenGraph(); }

        private static Result OpenGraph(string shaderPath=ShaderPath)
        {
            Shader shader = AssetDatabase.LoadAssetAtPath<Shader>(shaderPath);
            if (shader == null) throw new InvalidOperationException("Generate the ASE water shader first.");
            return new Result { success = AssetDatabase.OpenAsset(shader), shader = shaderPath };
        }

        private static void EnsureFolder()
        {
            Directory.CreateDirectory(Folder);AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
        }

        private static T LoadOrCreate<T>(string path, Func<T> factory) where T : Object
        {
            T existing = AssetDatabase.LoadAssetAtPath<T>(path);
            if (existing != null) return existing;
            if (File.Exists(path)) throw new IOException("Refusing to replace existing asset: " + path);
            T value = factory(); AssetDatabase.CreateAsset(value, path); return value;
        }

        private static Result CreateAssets()
        {
            EnsureFolder();
            Shader shader = AssetDatabase.LoadAssetAtPath<Shader>(ShaderPath);
            if (shader == null || ShaderUtil.ShaderHasError(shader)) throw new InvalidOperationException("Generate the ASE water shader successfully first.");
            if(shader.FindPropertyIndex("_WATER_CAUSTICS")<0) throw new InvalidOperationException("The water shader loaded by Unity is still the pre-toggle version. Reload the new ASE graph before creating its materials.");
            string slopePath = Folder + "/RippleSlope.png";
            if (!File.Exists(slopePath))
            {
                Texture2D slopes = MakeSlopes(512);
                File.WriteAllBytes(slopePath, slopes.EncodeToPNG()); Object.DestroyImmediate(slopes);
                AssetDatabase.ImportAsset(slopePath, ImportAssetOptions.ForceSynchronousImport);
                var importer = (TextureImporter)AssetImporter.GetAtPath(slopePath);
                importer.sRGBTexture = false;
                importer.mipmapEnabled = true;
                importer.wrapMode = TextureWrapMode.Repeat;
                importer.filterMode = FilterMode.Trilinear;
                importer.anisoLevel = 8;
                importer.textureCompression = TextureImporterCompression.Uncompressed;
                importer.SaveAndReimport();
            }
            Cubemap sky = LoadOrCreate(Folder + "/WaterSky.cubemap", MakeSky);
            Mesh grid = LoadOrCreate(Folder + "/WaterGrid.asset", () => MakeGrid(24, 128));
            Material material = LoadOrCreate(Folder + "/DeepWater.mat", () =>
            {
                var m = new Material(shader) { name = "DeepWater" };
                m.SetTexture("_RippleSlope", AssetDatabase.LoadAssetAtPath<Texture2D>(slopePath));
                return m;
            });
            EnsureCausticTexture();
            if (material.HasProperty("_CausticTex") && material.GetTexture("_CausticTex") == null)
            {
                material.SetTexture("_CausticTex",AssetDatabase.LoadAssetAtPath<Texture2D>(Folder+"/CausticLight.png"));
                EditorUtility.SetDirty(material);
            }
            if (material.HasProperty("_WATER_CAUSTICS") && material.GetTag("DeepWaterFeatureSetup",false,"") != "0.2.8")
            {
                SetFeatures(material,true);
                material.SetOverrideTag("DeepWaterFeatureSetup","0.2.8");
                EditorUtility.SetDirty(material);
            }
            var presetChecks=new System.Collections.Generic.List<VariantCheck>();
            foreach(string quality in new[]{"Low","Medium","High"})
            {
                var preset=LoadOrCreate(Folder+"/DeepWater_"+quality+".mat",()=>new Material(material) { name="DeepWater_"+quality });
                if(preset.GetTag("DeepWaterFeatureSetup",false,"")!="0.2.8")
                {
                    SetFeatures(preset,quality=="High");
                    if(quality=="Medium") foreach(string feature in new[]{"WAVES","RIPPLES","FRESNEL","DEPTH","SCATTER","REFRACTION"}) SetFeature(preset,feature,true);
                    if(quality=="Medium") {preset.SetFloat("_SpecularHighlights",1);preset.DisableKeyword("_SPECULARHIGHLIGHTS_OFF");}
                    if(quality=="Low") foreach(string feature in new[]{"FRESNEL","DEPTH","SCATTER"}) SetFeature(preset,feature,true);
                    preset.SetTexture("_CausticTex",AssetDatabase.LoadAssetAtPath<Texture2D>(Folder+"/CausticLight.png"));
                    preset.SetOverrideTag("DeepWaterFeatureSetup","0.2.8");
                    EditorUtility.SetDirty(preset);
                }
                AssetDatabase.SaveAssetIfDirty(preset);
                int pass=preset.FindPass("ForwardBase");
                bool compiled=pass>=0 && preset.SetPass(pass) && !ShaderUtil.ShaderHasError(shader);
                presetChecks.Add(new VariantCheck {name=quality,compiled=compiled,keywords=preset.shaderKeywords});
                if(!compiled) throw new InvalidOperationException("The "+quality+" preset failed ForwardBase compilation.");
            }
            string prefabPath = Folder + "/DeepWater.prefab";
            if (!File.Exists(prefabPath))
            {
                GameObject root = MakeWater(grid, material, sky);
                try { PrefabUtility.SaveAsPrefabAsset(root, prefabPath); }
                finally { Object.DestroyImmediate(root); }
            }
            AssetDatabase.SaveAssetIfDirty(grid);
            AssetDatabase.SaveAssetIfDirty(sky);
            EditorUtility.SetDirty(material);
            AssetDatabase.SaveAssetIfDirty(material);
            var result = RenderPreview();
            result.material = Folder + "/DeepWater.mat"; result.prefab = prefabPath;
            result.variants=presetChecks.ToArray();
            result.vertices = grid.vertexCount; result.triangles = grid.triangles.Length / 3;
            return result;
        }

        private static GameObject MakeWater(Mesh grid, Material material, Cubemap sky)
        {
            var root = new GameObject("DeepWater — depth, waves & shoreline");
            root.AddComponent<MeshFilter>().sharedMesh = grid;
            var renderer = root.AddComponent<MeshRenderer>();
            renderer.sharedMaterial = material;
            renderer.shadowCastingMode = ShadowCastingMode.Off;
            renderer.receiveShadows = true;
            renderer.reflectionProbeUsage = ReflectionProbeUsage.BlendProbes;
            root.AddComponent<DepthWaterSurface>();
            var probeGo = new GameObject("Optional sky reflection — replace with scene probe");
            probeGo.transform.SetParent(root.transform, false);
            var probe = probeGo.AddComponent<ReflectionProbe>();
            probe.mode = ReflectionProbeMode.Custom;
            probe.customBakedTexture = sky;
            probe.size = new Vector3(30, 14, 30);
            probe.center = new Vector3(0, 1, 0);
            probe.blendDistance = 2;
            probe.boxProjection = false;
            probe.intensity = 1;
            return root;
        }

        private static void SetFeature(Material m,string feature,bool enabled)
        {
            string property="_WATER_"+feature;
            m.SetFloat(property,enabled ? 1 : 0);
            if(enabled) m.EnableKeyword(property+"_ON"); else m.DisableKeyword(property+"_ON");
        }

        private static void SetFeatures(Material m,bool enabled)
        {
            foreach(string feature in Features) SetFeature(m,feature,enabled);
            foreach(string property in new[]{"_SpecularHighlights","_GlossyReflections"})
                m.SetFloat(property,enabled ? 1 : 0);
            if(enabled) {m.DisableKeyword("_SPECULARHIGHLIGHTS_OFF");m.DisableKeyword("_GLOSSYREFLECTIONS_OFF");}
            else {m.EnableKeyword("_SPECULARHIGHLIGHTS_OFF");m.EnableKeyword("_GLOSSYREFLECTIONS_OFF");}
        }

        private static void EnsureCausticTexture()
        {
            string path=Folder+"/CausticLight.png";
            if(File.Exists(path)) return;
            const int n=512,cells=5;
            var rng=new System.Random(280621);
            var points=new Vector2[cells*cells];
            for(int i=0;i<points.Length;i++) points[i]=new Vector2(.18f+(float)rng.NextDouble()*.64f,.18f+(float)rng.NextDouble()*.64f);
            var pixels=new Color[n*n];
            for(int y=0;y<n;y++) for(int x=0;x<n;x++)
            {
                float u=(float)x/n,v=(float)y/n;
                // Periodic domain warp and periodic Voronoi edges. No downloaded art.
                float px=u*cells+.20f*Mathf.Sin(v*12.56637f)+.09f*Mathf.Sin(u*6.283185f+v*18.84956f);
                float py=v*cells+.20f*Mathf.Sin(u*12.56637f)+.09f*Mathf.Cos(v*6.283185f-u*18.84956f);
                int ix=Mathf.FloorToInt(px),iy=Mathf.FloorToInt(py);
                float first=100,second=100;
                for(int dy=-1;dy<=1;dy++) for(int dx=-1;dx<=1;dx++)
                {
                    int cx=ix+dx,cy=iy+dy;
                    Vector2 p=points[((cy%cells+cells)%cells)*cells+(cx%cells+cells)%cells];
                    float d=(new Vector2(cx+p.x-px,cy+p.y-py)).sqrMagnitude;
                    if(d<first) {second=first;first=d;} else if(d<second) second=d;
                }
                float gap=Mathf.Sqrt(second)-Mathf.Sqrt(first);
                float ridge=Mathf.Exp(-gap*gap*95);
                pixels[y*n+x]=new Color(ridge,ridge,ridge,1);
            }
            var texture=new Texture2D(n,n,TextureFormat.RGB24,false,true);
            try {texture.SetPixels(pixels);texture.Apply();File.WriteAllBytes(path,texture.EncodeToPNG());}
            finally {Object.DestroyImmediate(texture);}
            AssetDatabase.ImportAsset(path,ImportAssetOptions.ForceSynchronousImport);
            var importer=(TextureImporter)AssetImporter.GetAtPath(path);
            importer.sRGBTexture=false;importer.mipmapEnabled=true;importer.wrapMode=TextureWrapMode.Repeat;
            importer.filterMode=FilterMode.Trilinear;importer.anisoLevel=8;
            importer.textureCompression=TextureImporterCompression.Uncompressed;importer.SaveAndReimport();
        }

        private static Mesh MakeGrid(float size, int n)
        {
            var positions = new Vector3[(n + 1) * (n + 1)];
            var normals = new Vector3[positions.Length];
            var tangents = new Vector4[positions.Length];
            var uv = new Vector2[positions.Length];
            var triangles = new int[n * n * 6];
            for (int z = 0; z <= n; z++) for (int x = 0; x <= n; x++)
            {
                int i = z * (n + 1) + x;
                positions[i] = new Vector3(((float)x / n - .5f) * size, 0, ((float)z / n - .5f) * size);
                normals[i] = Vector3.up; tangents[i] = new Vector4(1, 0, 0, -1);
                uv[i] = new Vector2((float)x / n, (float)z / n);
            }
            int t = 0;
            for (int z = 0; z < n; z++) for (int x = 0; x < n; x++)
            {
                int i = z * (n + 1) + x;
                triangles[t++] = i; triangles[t++] = i + n + 1; triangles[t++] = i + 1;
                triangles[t++] = i + 1; triangles[t++] = i + n + 1; triangles[t++] = i + n + 2;
            }
            var mesh = new Mesh { name = "WaterGrid_24m_128x128", vertices = positions,
                normals = normals, tangents = tangents, uv = uv, triangles = triangles };
            mesh.bounds = new Bounds(Vector3.zero, new Vector3(size, 3, size));
            return mesh;
        }

        private static Texture2D MakeSlopes(int size)
        {
            // Integer Fourier modes guarantee exact periodic wrapping and matching derivatives.
            const int count = 36;
            var rng = new System.Random(194207);
            var kx = new int[count]; var ky = new int[count];
            var amp = new float[count]; var phase = new float[count];
            float total = 0;
            for (int i = 0; i < count; i++)
            {
                kx[i] = rng.Next(-14, 15); ky[i] = rng.Next(2, 22);
                float k = Mathf.Sqrt(kx[i] * kx[i] + ky[i] * ky[i]);
                amp[i] = 1f / Mathf.Pow(k, 1.35f);
                phase[i] = (float)rng.NextDouble() * 6.283185f;
                total += amp[i];
            }
            var pixels = new Color[size * size];
            for (int y = 0; y < size; y++) for (int x = 0; x < size; x++)
            {
                float sx = 0, sy = 0, noise = 0;
                for (int i = 0; i < count; i++)
                {
                    float a = 6.283185f * (kx[i] * (float)x / size + ky[i] * (float)y / size) + phase[i];
                    float k = Mathf.Sqrt(kx[i] * kx[i] + ky[i] * ky[i]);
                    float c = Mathf.Cos(a) * amp[i];
                    sx += c * kx[i] / k; sy += c * ky[i] / k;
                    noise += Mathf.Sin(a) * amp[i];
                }
                // Store signed slope around 0.5. This is linear data, not an imported normal map.
                pixels[y * size + x] = new Color(Mathf.Clamp01(.5f + sx / total * 1.2f),
                    Mathf.Clamp01(.5f + sy / total * 1.2f), Mathf.Clamp01(.5f + noise / total * 1.7f), 1);
            }
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false, true);
            tex.SetPixels(pixels); tex.Apply(); return tex;
        }

        private static Cubemap MakeSky()
        {
            const int size = 128;
            var cube = new Cubemap(size, TextureFormat.RGBAHalf, true) { name = "Original soft daylight water reflection" };
            Vector3 sun = new Vector3(-.6f, .5f, -.5f).normalized;
            for (int face = 0; face < 6; face++)
            {
                var pixels = new Color[size * size];
                for (int y = 0; y < size; y++) for (int x = 0; x < size; x++)
                {
                    float u = (x + .5f) / size * 2 - 1, v = (y + .5f) / size * 2 - 1;
                    Vector3 d;
                    switch ((CubemapFace)face)
                    {
                        case CubemapFace.PositiveX: d = new Vector3(1, -v, -u); break;
                        case CubemapFace.NegativeX: d = new Vector3(-1, -v, u); break;
                        case CubemapFace.PositiveY: d = new Vector3(u, 1, v); break;
                        case CubemapFace.NegativeY: d = new Vector3(u, -1, -v); break;
                        case CubemapFace.PositiveZ: d = new Vector3(u, -v, 1); break;
                        default: d = new Vector3(-u, -v, -1); break;
                    }
                    d.Normalize();
                    Color c = Color.Lerp(new Color(.66f,.79f,.83f).linear, new Color(.12f,.34f,.52f).linear,
                        Mathf.Pow(Mathf.Clamp01(d.y), .6f));
                    float cloud = Mathf.Sin(d.x * 14 + d.z * 9) * Mathf.Sin(d.z * 18 - d.x * 5) +
                        .45f * Mathf.Sin(d.x * 31 + d.z * 25);
                    cloud = Mathf.SmoothStep(.18f, .86f, Mathf.Clamp01((cloud - .12f) * .7f)) * Mathf.SmoothStep(0, .3f, d.y);
                    c = Color.Lerp(c, new Color(.86f,.88f,.85f).linear, cloud * .65f);
                    c += new Color(1,.84f,.61f) * Mathf.Pow(Mathf.Max(0, Vector3.Dot(d,sun)), 1600) * 5;
                    if (d.y < 0) c = Color.Lerp(new Color(.12f,.16f,.14f).linear,c,Mathf.Exp(d.y * 9));
                    pixels[y * size + x] = c;
                }
                cube.SetPixels(pixels, (CubemapFace)face);
            }
            cube.Apply(true, false); return cube;
        }

        private static GameObject MakeBed(Material material)
        {
            const int n = 100; const float size = 38;
            var mesh = MakeGrid(size, n);
            var verts = mesh.vertices;
            for (int i = 0; i < verts.Length; i++)
            {
                float x = verts[i].x, z = verts[i].z;
                verts[i].y = -.85f - .23f * x + .18f * Mathf.Sin(z * .6f) +
                    .05f * Mathf.Sin(x * 2.1f + z) + .04f * Mathf.Sin(z * 3.5f - x);
            }
            mesh.vertices = verts; mesh.RecalculateNormals(); mesh.RecalculateBounds();
            var go = new GameObject("Sand shelf sloping into deep water");
            go.AddComponent<MeshFilter>().sharedMesh = mesh;
            go.AddComponent<MeshRenderer>().sharedMaterial = material;
            return go;
        }

        private static Texture2D MakeSand()
        {
            const int n = 256;
            var tex = new Texture2D(n,n,TextureFormat.RGB24,true) { wrapMode=TextureWrapMode.Repeat };
            var p = new Color[n*n]; var rng = new System.Random(78);
            for(int y=0;y<n;y++) for(int x=0;x<n;x++)
            {
                float ripple=Mathf.Sin(x*.15f+Mathf.Sin(y*.032f)*2)*.025f;
                float grain=(float)rng.NextDouble()*.12f-.06f;
                p[y*n+x]=new Color(.61f+grain+ripple,.56f+grain+ripple,.43f+grain+ripple);
            }
            tex.SetPixels(p);tex.Apply();return tex;
        }

        private static Material PreviewMaterial(string shaderPath)
        {
            EnsureCausticTexture();
            var source=AssetDatabase.LoadAssetAtPath<Material>(Folder+"/DeepWater.mat");
            var shader=AssetDatabase.LoadAssetAtPath<Shader>(shaderPath);
            if(source==null || shader==null) throw new InvalidOperationException("Water shader/material is missing.");
            var m=new Material(source) {shader=shader};
            if(m.HasProperty("_CausticTex")) m.SetTexture("_CausticTex",AssetDatabase.LoadAssetAtPath<Texture2D>(Folder+"/CausticLight.png"));
            if(m.HasProperty("_WATER_CAUSTICS") && m.GetTag("DeepWaterFeatureSetup",false,"")!="0.2.8") SetFeatures(m,true);
            return m;
        }

        private static Result RenderPreview(string shaderPath=ShaderPath)
        {
            var m=PreviewMaterial(shaderPath);
            try {return RenderPreview(m,Folder+"/DeepWater_Preview.png",1600,1000,out _);}
            finally {Object.DestroyImmediate(m);}
        }

        private static Result ValidateVariants(string shaderPath)
        {
            var m=PreviewMaterial(shaderPath);
            var checks=new System.Collections.Generic.List<VariantCheck>();
            string directory=Jobs+"/Validation";
            Directory.CreateDirectory(directory);
            try
            {
                // All wave/foam motion uses WaveSpeed; caustics has its own speed.
                // Zero both to compare identical geometry and noise phase across renders.
                m.SetFloat("_WaveSpeed",0);m.SetFloat("_CausticSpeed",0);
                SetFeatures(m,true);
                string baselinePath=directory+"/AllOn.png";
                Result baseline=RenderPreview(m,baselinePath,960,600,out Color32[] reference);
                checks.Add(new VariantCheck {name="AllOn",compiled=baseline.compiled,preview=baselinePath,keywords=m.shaderKeywords});
                string[] effects=Features.Concat(new[]{"SPECULAR","REFLECTION"}).ToArray();
                foreach(bool singleOn in new[]{false,true}) foreach(string effect in effects)
                {
                    SetFeatures(m,!singleOn);
                    if(effect=="SPECULAR" || effect=="REFLECTION")
                    {
                        string property=effect=="SPECULAR" ? "_SpecularHighlights" : "_GlossyReflections";
                        string keyword=effect=="SPECULAR" ? "_SPECULARHIGHLIGHTS_OFF" : "_GLOSSYREFLECTIONS_OFF";
                        m.SetFloat(property,singleOn ? 1 : 0);
                        if(singleOn) m.DisableKeyword(keyword);else m.EnableKeyword(keyword);
                    }
                    else SetFeature(m,effect,singleOn);
                    string name=(singleOn ? "Only_" : "Without_")+effect;
                    string path=directory+"/"+name+".png";
                    Result result=RenderPreview(m,path,960,600,out Color32[] pixels);
                    double difference=0;int changed=0;
                    for(int i=0;i<pixels.Length;i++)
                    {
                        int d=Math.Abs(pixels[i].r-reference[i].r)+Math.Abs(pixels[i].g-reference[i].g)+Math.Abs(pixels[i].b-reference[i].b);
                        difference+=d;if(d>6) changed++;
                    }
                    checks.Add(new VariantCheck {name=name,compiled=result.compiled,preview=path,keywords=m.shaderKeywords,
                        changedPixels=changed,meanAbsoluteDifference=(float)(difference/(pixels.Length*3*255.0))});
                }
                SetFeatures(m,false);
                Result off=RenderPreview(m,directory+"/AllOff.png",960,600,out _);
                checks.Add(new VariantCheck {name="AllOff",compiled=off.compiled,preview=off.preview,keywords=m.shaderKeywords});
                baseline.variants=checks.ToArray();baseline.success=checks.All(c=>c.compiled);
                if(!baseline.success) baseline.error="At least one feature keyword combination failed ForwardBase compilation.";
                return baseline;
            }
            finally {Object.DestroyImmediate(m);}
        }

        private static Result RenderPreview(Material material,string imagePath,int width,int height,out Color32[] pixels)
        {
            EnsureFolder();
            Shader shader = material.shader;
            Cubemap sky = AssetDatabase.LoadAssetAtPath<Cubemap>(Folder + "/WaterSky.cubemap");
            Mesh grid = AssetDatabase.LoadAssetAtPath<Mesh>(Folder + "/WaterGrid.asset");
            if (shader == null || material == null || sky == null || grid == null) throw new InvalidOperationException("Water supporting assets are missing.");
            var preview = new PreviewRenderUtility();
            Material sand = null, rock = null, skyMat = null;
            Texture2D sandTexture = null, image = null;
            Mesh bedMesh = null;
            try
            {
                preview.ambientColor = new Color(.18f,.22f,.25f);
                preview.cameraFieldOfView = 43;
                preview.camera.nearClipPlane = .1f; preview.camera.farClipPlane = 120;
                preview.camera.depthTextureMode = DepthTextureMode.Depth;
                preview.camera.allowHDR = false; preview.camera.allowMSAA = false;
                preview.camera.transform.position = new Vector3(-7.5f,6.2f,-10.6f);
                preview.camera.transform.LookAt(new Vector3(.5f,-.5f,.4f));
                preview.camera.clearFlags = CameraClearFlags.Skybox;
                skyMat = new Material(Shader.Find("Skybox/Cubemap")); skyMat.SetTexture("_Tex",sky);
                preview.camera.gameObject.AddComponent<Skybox>().material = skyMat;
                preview.lights[0].intensity = 1.2f;
                preview.lights[0].color = new Color(1,.94f,.83f);
                preview.lights[0].transform.rotation = Quaternion.Euler(38,-35,0);
                preview.lights[1].intensity = .15f;
                preview.lights[1].transform.rotation = Quaternion.Euler(45,130,0);
                preview.AddSingleGO(MakeWater(grid,material,sky));
                sand = new Material(Shader.Find("Standard"));
                sandTexture = MakeSand(); sand.mainTexture = sandTexture;
                sand.mainTextureScale = new Vector2(24,24); sand.SetFloat("_Glossiness",.12f);
                GameObject bed = MakeBed(sand); bedMesh=bed.GetComponent<MeshFilter>().sharedMesh;
                preview.AddSingleGO(bed);
                rock = new Material(Shader.Find("Standard")); rock.color = new Color(.29f,.31f,.29f); rock.SetFloat("_Glossiness",.22f);
                var rng = new System.Random(71);
                for(int i=0;i<13;i++)
                {
                    GameObject stone=GameObject.CreatePrimitive(PrimitiveType.Sphere);
                    stone.name="Preview shore stone";
                    float x=-4.1f+(float)rng.NextDouble()*3.1f;
                    float z=-4.5f+(float)rng.NextDouble()*11;
                    stone.transform.position=new Vector3(x,-.85f-.23f*x,z);
                    stone.transform.localScale=new Vector3(.55f+(float)rng.NextDouble()*.85f,.6f+(float)rng.NextDouble(),.8f+(float)rng.NextDouble());
                    stone.GetComponent<Renderer>().sharedMaterial=rock;
                    preview.AddSingleGO(stone);
                }
                preview.BeginStaticPreview(new Rect(0,0,width,height));
                preview.Render();
                image=preview.EndStaticPreview();
                pixels=image.GetPixels32();
                File.WriteAllBytes(imagePath,image.EncodeToPNG());
                if(imagePath.StartsWith("Assets/",StringComparison.Ordinal)) AssetDatabase.ImportAsset(imagePath,ImportAssetOptions.ForceSynchronousImport);
                // GrabPass is not an executable material pass. Compile the actual forward color pass.
                int mainPassIndex = material.FindPass("ForwardBase");
                bool compiled = mainPassIndex >= 0 && material.SetPass(mainPassIndex) && !ShaderUtil.ShaderHasError(shader);
                return new Result {success=compiled,compiled=compiled,shader=AssetDatabase.GetAssetPath(shader),
                    error=compiled ? "" : "The ForwardBase color pass could not be compiled or selected.",
                    preview=imagePath,graphicsApi=SystemInfo.graphicsDeviceType.ToString(),shaderPasses=material.passCount,
                    propertyCount=shader.GetPropertyCount(),materialKeywords=material.shaderKeywords,
                    mainPass="ForwardBase",mainPassIndex=mainPassIndex,
                    compilerMessages=ShaderUtil.GetShaderMessages(shader).Select(m=>m.severity+": "+m.message).ToArray()};
            }
            finally
            {
                preview.Cleanup();
                foreach(var obj in new Object[]{sand,rock,skyMat,sandTexture,image,bedMesh}) if(obj!=null) Object.DestroyImmediate(obj);
            }
        }
    }
}
