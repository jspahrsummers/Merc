using System.Collections.Generic;
using UnityEngine;

/// <summary>Implements a glow effect like that of a rocket engine.</summary>
public sealed class GlowController : MonoBehaviour
{
    [Tooltip("Objects which appear when glowing and disappear when not glowing.")]
    public List<GameObject> glowingObjects;

    public void OnEnable()
    {
        SetVisible(false);
    }

    /// <summary>Changes whether the engine glow is visible.</summary>
    /// <remarks>This may animate the visibility transition in the future.</remarks>
    public void SetVisible(bool visible)
    {
        foreach (var obj in glowingObjects)
        {
            obj.SetActive(visible);
        }
    }
}
