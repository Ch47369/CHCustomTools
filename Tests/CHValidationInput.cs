// Keep disposable Scene fixtures deterministic while the desktop remains in use.
using UnityEditor;
using UnityEngine;
public static class CHValidationInput
{
    static bool installed, sending;
    public static void Install()
    {
        if (installed) return; installed = true;
        SceneView.beforeSceneGui += view =>
        {
            var e = Event.current;
            if (!sending && (e.isMouse || e.isKey || e.type == EventType.ScrollWheel)) e.Use();
        };
    }
    public static bool Send(EditorWindow window, Event e)
    {
        bool prior = sending; sending = true;
        try { return window.SendEvent(e); } finally { sending = prior; }
    }
}
