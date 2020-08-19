using UnityEngine;

/// <summary>Displays a single system on the galaxy map screen, and handles UI behaviors related to it.</summary>
public sealed class GalaxyMapSystemController : MonoBehaviour
{
    public void SetSelected(bool selected)
    {
        Debug.Log($"{gameObject.name} selected: {selected}");
    }
}
