using UnityEngine;

namespace ASEShaderWater
{
    /// <summary>Enables the Built-in scene depth texture for cameras rendering this water.</summary>
    [ExecuteAlways, DisallowMultipleComponent, RequireComponent(typeof(Renderer))]
    public sealed class DepthWaterSurface : MonoBehaviour
    {
        private Renderer waterRenderer;

        private void OnEnable()
        {
            waterRenderer = GetComponent<Renderer>();
            Camera.onPreCull += PrepareCamera;
        }

        private void OnDisable() { Camera.onPreCull -= PrepareCamera; }

        private void PrepareCamera(Camera camera)
        {
            if (camera == null || waterRenderer == null || !waterRenderer.enabled ||
                !gameObject.activeInHierarchy || (camera.cullingMask & (1 << gameObject.layer)) == 0)
                return;
            if (camera.cameraType == CameraType.Reflection) return;
            // Preserve other depth consumers' flags. This component never removes them.
            camera.depthTextureMode |= DepthTextureMode.Depth;
        }
    }
}
