using System;
using System.Collections.Generic;
using System.IO;
using CH.CustomTools.Paths;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CH.CustomTools.VFX
{
    [Serializable]
    public sealed class ParticleTrailData
    {
        [SerializeField] internal string objectId, sessionId;
        [SerializeField] public List<PathKnot> knots = new List<PathKnot>();
        [SerializeField] public float Duration = 2f;
        [SerializeField] public string BakedSignature;

        public static void ImportPath(ParticleSystem target, BezierPath source, bool reverse)
        {
            if (!ParticleTrailBaker.CanEdit(target) || source == null || EditorUtility.IsPersistent(source))
                throw new ArgumentException("Choose a scene path and a particle system.");
            source.ValidatePath();
            int count = source.knots.Count + (source.closed ? 1 : 0);
            if (count > ParticleTrailCurve.MaxPoints) throw new ArgumentException("The particle trail supports at most 128 points.");
            var knots = new List<PathKnot>(count);
            var toLocal = target.transform.worldToLocalMatrix * source.transform.localToWorldMatrix;
            for (int i = 0; i < count; i++)
            {
                int index = i % source.knots.Count;
                var knot = source.knots[index];
                knots.Add(new PathKnot(toLocal.MultiplyPoint3x4(knot.position))
                {
                    automatic = false,
                    incoming = toLocal.MultiplyVector(source.Handle(index, false) - knot.position),
                    outgoing = toLocal.MultiplyVector(source.Handle(index, true) - knot.position)
                });
            }
            if (reverse) ReverseKnots(knots);
            // Validate before replacing existing editor data.
            new ParticleTrailCurve(knots, target.transform.localToWorldMatrix);
            ParticleTrailStore.Change(target, "Import scene path for particle trail", data => data.knots = knots);
        }

        public static void ReversePath(ParticleSystem target)
        {
            ParticleTrailStore.Change(target, "Reverse particle trail path", data =>
            {
                ReverseKnots(data.knots);
            });
        }

        static void ReverseKnots(List<PathKnot> knots)
        {
            knots.Reverse();
            foreach (var knot in knots)
            {
                var incoming = knot.incoming;
                knot.incoming = knot.outgoing;
                knot.outgoing = incoming;
            }
        }

        public Vector3 Handle(int index, bool outgoing)
        {
            return ParticleTrailCurve.Handle(knots, index, outgoing);
        }

        internal void FreezeTangents(int index)
        {
            var knot = knots[index];
            if (!knot.automatic) return;
            var incoming = Handle(index, false) - knot.position;
            var outgoing = Handle(index, true) - knot.position;
            knot.automatic = false;
            knot.incoming = incoming;
            knot.outgoing = outgoing;
        }
    }

    // Project authoring data lives outside scenes, prefabs, and the player build.
    [FilePath("ProjectSettings/CHCustomToolsParticleTrailPaths.asset", FilePathAttribute.Location.ProjectFolder)]
    public sealed class ParticleTrailStore : ScriptableSingleton<ParticleTrailStore>
    {
        [SerializeField] List<ParticleTrailData> paths = new List<ParticleTrailData>();
        const string SessionKey = "CH.ParticleTrail.Session";
        static string Session
        {
            get
            {
                string id = SessionState.GetString(SessionKey, "");
                if (string.IsNullOrEmpty(id))
                {
                    id = Guid.NewGuid().ToString("N");
                    SessionState.SetString(SessionKey, id);
                }
                return id;
            }
        }

        [InitializeOnLoadMethod]
        static void Initialize()
        {
            EditorSceneManager.sceneSaved += _ => RefreshIdentities();
            PrefabStage.prefabSaved += _ => RefreshIdentities();
            Undo.undoRedoPerformed += () =>
            {
                if (instance.paths.Count > 0 || File.Exists("ProjectSettings/CHCustomToolsParticleTrailPaths.asset"))
                    instance.Save(true);
                SceneView.RepaintAll();
            };
        }

        static string SessionId(ParticleSystem target) => Session + ":" + target.GetInstanceID();

        static string StableId(ParticleSystem target)
        {
            var id = GlobalObjectId.GetGlobalObjectIdSlow(target);
            if (id.identifierType != 0 && id.assetGUID.ToString() != "00000000000000000000000000000000" &&
                id.targetObjectId != 0)
                return id.ToString();

            // Prefab Mode may use a preview scene with no scene asset GUID. Resolve the
            // corresponding saved object by its hierarchy, using the prefab asset's ID.
            var stage = PrefabStageUtility.GetPrefabStage(target.gameObject);
            if (stage == null) return null;
            var indices = new Stack<int>();
            for (Transform current = target.transform; current != stage.prefabContentsRoot.transform; current = current.parent)
            {
                if (current == null || current.parent == null) return null;
                indices.Push(current.GetSiblingIndex());
            }
            var asset = AssetDatabase.LoadAssetAtPath<GameObject>(stage.assetPath);
            if (asset == null) return null;
            var transform = asset.transform;
            var staged = stage.prefabContentsRoot.transform;
            while (indices.Count > 0)
            {
                int index = indices.Pop();
                if (index >= transform.childCount || index >= staged.childCount) return null;
                transform = transform.GetChild(index);
                staged = staged.GetChild(index);
                if (transform.name != staged.name) return null;
            }
            var persistent = transform.GetComponent<ParticleSystem>();
            return persistent == null ? null : GlobalObjectId.GetGlobalObjectIdSlow(persistent).ToString();
        }

        public static ParticleTrailData Find(ParticleSystem target)
        {
            if (target == null) return null;
            string session = SessionId(target);
            var data = instance.paths.Find(path => path.sessionId == session);
            if (data != null) return data;
            string stable = StableId(target);
            if (string.IsNullOrEmpty(stable)) return null;
            data = instance.paths.Find(path => path.objectId == stable);
            if (data != null) data.sessionId = session;
            return data;
        }

        public static ParticleTrailData GetOrCreate(ParticleSystem target)
        {
            if (!ParticleTrailBaker.CanEdit(target)) throw new ArgumentException("Select an editable particle system.");
            var data = Find(target);
            if (data != null) return data;
            Undo.RegisterCompleteObjectUndo(instance, "Create particle trail path");
            data = new ParticleTrailData { objectId = StableId(target), sessionId = SessionId(target) };
            var legacy = target.GetComponent<ParticleTrailPath>();
            if (legacy != null)
            {
                foreach (var point in legacy.Points) data.knots.Add(new PathKnot(point));
                data.Duration = legacy.Duration;
                data.BakedSignature = legacy.BakedSignature;
            }
            instance.paths.Add(data);
            Commit();
            return data;
        }

        public static void Change(ParticleSystem target, string label, Action<ParticleTrailData> change)
        {
            var data = GetOrCreate(target);
            Undo.RecordObject(instance, label);
            change(data);
            Commit();
            SceneView.RepaintAll();
        }

        internal static void Record(string label) => Undo.RegisterCompleteObjectUndo(instance, label);

        internal static void Commit()
        {
            EditorUtility.SetDirty(instance);
            instance.Save(true);
        }

        static void RefreshIdentities()
        {
            string prefix = Session + ":";
            bool changed = false;
            foreach (var path in instance.paths)
            {
                if (string.IsNullOrEmpty(path.sessionId) || !path.sessionId.StartsWith(prefix, StringComparison.Ordinal) ||
                    !int.TryParse(path.sessionId.Substring(prefix.Length), out int id)) continue;
                var target = EditorUtility.InstanceIDToObject(id) as ParticleSystem;
                if (target == null) continue;
                string stable = StableId(target);
                if (string.IsNullOrEmpty(stable) || stable == path.objectId) continue;
                path.objectId = stable;
                changed = true;
            }
            if (changed) Commit();
        }
    }
}
