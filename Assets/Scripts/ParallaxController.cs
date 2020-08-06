using System.Collections.Generic;
using UnityEngine;

/// <summary>Repeats objects to create an infinite parallax scrolling effect. The renderer is assumed to be fixed on the Z axis, so only X and Y dimensions will be repeated.</summary>
public sealed class ParallaxController : MonoBehaviour
{

    [Tooltip("A prefab for spawning the parallax instances which will be used to create a repeating background.")]
    public ParallaxInstanceController instancePrefab;

    /// <summary>Contains a grid of all parallax instances.</summary>
    private static Dictionary<(int x, int y), ParallaxInstanceController> allControllers = new Dictionary<(int x, int y), ParallaxInstanceController>();

    public static ParallaxController Find()
    {
        return GameObject.FindWithTag("ParallaxController").GetComponent<ParallaxController>();
    }

    public void EnsureInstanceAtLocation((int x, int y) gridLocation)
    {
        if (allControllers.ContainsKey(gridLocation))
        {
            return;
        }

        Transform rendererTransform = instancePrefab.renderer.transform;
        var newPosition = new Vector3(rendererTransform.localScale.x * gridLocation.x, rendererTransform.localScale.y * gridLocation.y, 0);
        var controller = Instantiate<ParallaxInstanceController>(instancePrefab, newPosition, Quaternion.identity, transform);

        controller.gridLocation = gridLocation;
        controller.gameObject.name = $"{instancePrefab.name} ({gridLocation.x}, {gridLocation.y})";

        Debug.Assert(!allControllers.ContainsKey(gridLocation));
        allControllers[gridLocation] = controller;
    }

    public void RemoveInstance((int x, int y) location)
    {
        allControllers.Remove(location);

        // Ensures that if the scene resets (or the player teleports to the origin), we always present a background.
        if (allControllers.Count == 0)
        {
            CreateRootInstance();
        }
    }

    void Start()
    {
        CreateRootInstance();
    }

    private void CreateRootInstance()
    {
        EnsureInstanceAtLocation((0, 0));
    }
}