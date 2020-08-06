using UnityEngine;

/// <summary>Attached to a renderer as part of an infinite parallax scrolling effect, coordinated by ParallaxController.</summary>
public sealed class ParallaxInstanceController : MonoBehaviour
{
    [Tooltip("The renderer for this instance.")]
    public new Renderer renderer;

    /// <summary>Indices into a grid, identifying which controller this is. The origin is (0, 0).</summary>
    internal (int x, int y) gridLocation;

    void OnBecameInvisible()
    {
        Destroy(gameObject);
    }

    void OnDestroy()
    {
        ParallaxController.Find()?.RemoveInstance(gridLocation);
    }

    void Update()
    {
        Vector3 minPoint = Camera.main.WorldToScreenPoint(renderer.bounds.min);
        Vector3 maxPoint = Camera.main.WorldToScreenPoint(renderer.bounds.max);

        if (minPoint.x >= 0)
        {
            ParallaxController.Find().EnsureInstanceAtLocation((gridLocation.x - 1, gridLocation.y));
        }

        if (maxPoint.x <= Screen.width)
        {
            ParallaxController.Find().EnsureInstanceAtLocation((gridLocation.x + 1, gridLocation.y));
        }

        if (minPoint.y >= 0)
        {
            ParallaxController.Find().EnsureInstanceAtLocation((gridLocation.x, gridLocation.y - 1));
        }

        if (maxPoint.y <= Screen.height)
        {
            ParallaxController.Find().EnsureInstanceAtLocation((gridLocation.x, gridLocation.y + 1));
        }
    }
}