using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

/// <summary>Controls the galaxy map screen in the UI, where the player can select hyperspace destinations and plan their route.</summary>
public sealed class GalaxyMapController : MonoBehaviour
{
    [Tooltip("The list of systems being presented on the map.")]
    public List<GalaxyMapSystemController> systems;

    void Start()
    {
        foreach (var system in systems)
        {
            system.clicked.AddListener(SystemClicked);
        }
    }

    void OnEnable()
    {
        Scene activeScene = SceneManager.GetActiveScene();
        foreach (var system in systems)
        {
            system.SetSelected(system.name == activeScene.name);
        }
    }

    private void SystemClicked(GalaxyMapSystemController system)
    {
        Debug.Log($"{system} clicked");
    }
}
