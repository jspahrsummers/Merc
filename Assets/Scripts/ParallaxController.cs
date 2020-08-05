using System.Collections.Generic;
using UnityEngine;

/// <summary>Repeats a renderer to create an infinite parallax scrolling effect. The renderer is assumed to be fixed on the Z axis, so only X and Y dimensions will be repeated.</summary>
public sealed class ParallaxController : MonoBehaviour
{
    [Tooltip("A reference to this object's own prefab type, so that it can be spawned to create a repeating background.")]
    public ParallaxController prefab;

    [Tooltip("The renderer, attached to the prefab, which will be repeated infinitely.")]
    public Renderer repeatingRenderer;

    /// <summary>Indices into a grid, identifying which parallax controller this is. The origin is (0, 0).</summary>
    private (int x, int y) gridTag;

    /// <summary>Contains a grid of all enabled parallax controllers.</summary>
    private static Dictionary<(int x, int y), ParallaxController> allControllers = new Dictionary<(int x, int y), ParallaxController>();

    private ParallaxController GetControllerAtOffset(int xOffset, int yOffset, bool instantiate = false)
    {
        var lookupTag = (x: gridTag.x + xOffset, y: gridTag.y + yOffset);
        if (allControllers.ContainsKey(lookupTag))
        {
            return allControllers[lookupTag];
        }
        else
        {
            return null;
        }
    }

    private ParallaxController left => GetControllerAtOffset(-1, 0);
    private ParallaxController right => GetControllerAtOffset(1, 0);
    private ParallaxController top => GetControllerAtOffset(0, 1);
    private ParallaxController bottom => GetControllerAtOffset(0, -1);

    private void InstantiateControllerAtOffset(int xOffset, int yOffset)
    {
        var newTag = (x: gridTag.x + xOffset, y: gridTag.y + yOffset);

        Vector3 newPosition = transform.position;
        newPosition.x += repeatingRenderer.transform.localScale.x * xOffset;
        newPosition.y += repeatingRenderer.transform.localScale.y * yOffset;

        var controller = Instantiate<ParallaxController>(prefab, newPosition, transform.rotation, transform.parent);
        controller.gridTag = newTag;

        Debug.Assert(!allControllers.ContainsKey(newTag));
        allControllers[newTag] = controller;
    }

    void OnBecameInvisible()
    {
        Destroy(gameObject);
    }

    void OnDestroy()
    {
        allControllers.Remove(gridTag);
    }

    void Start()
    {
        if (!allControllers.ContainsKey(gridTag))
        {
            allControllers[gridTag] = this;
        }
    }

    void Update()
    {
        Vector3 minPoint = Camera.main.WorldToScreenPoint(repeatingRenderer.bounds.min);
        Vector3 maxPoint = Camera.main.WorldToScreenPoint(repeatingRenderer.bounds.max);

        if (minPoint.x >= 0 && !left)
        {
            InstantiateControllerAtOffset(-1, 0);
        }

        if (maxPoint.x <= Screen.width && !right)
        {
            InstantiateControllerAtOffset(1, 0);
        }

        if (minPoint.y >= 0 && !bottom)
        {
            InstantiateControllerAtOffset(0, -1);
        }

        if (maxPoint.y <= Screen.height && !top)
        {
            InstantiateControllerAtOffset(0, 1);
        }
    }
}