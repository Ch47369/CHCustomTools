using System.Collections.Generic;
using UnityEngine;

namespace CH.CustomTools.VFX
{
    [AddComponentMenu("")]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(ParticleSystem))]
    public sealed class ParticleTrailPath : MonoBehaviour
    {
        [SerializeField, HideInInspector] private List<Vector3> points = new List<Vector3>();
        [SerializeField, HideInInspector] private float duration = 2f;
        [SerializeField, HideInInspector] private string bakedSignature;

        public List<Vector3> Points => points;
        public float Duration { get => duration; set => duration = value; }
        public string BakedSignature { get => bakedSignature; set => bakedSignature = value; }
    }
}
