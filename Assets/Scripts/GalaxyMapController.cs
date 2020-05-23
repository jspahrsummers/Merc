using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

/// <summary>Controls the galaxy map screen in the UI, where the player can select hyperspace destinations and plan their route.</summary>
public sealed class GalaxyMapController : MonoBehaviour
{
    [Tooltip("The list of systems being presented on the map.")]
    public List<GalaxyMapSystemController> systems;

    private GalaxyMapSystemController _selectedSystem;

    /// <summary>The system in the map that the user has selected, or null if there is no current selection.</summary>
    public GalaxyMapSystemController selectedSystem
    {
        get => _selectedSystem;
        set
        {
            _selectedSystem = value;
            foreach (var system in systems)
            {
                system.selected = system == value;
            }
        }
    }

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
            system.currentSystem = system.name == activeScene.name;
        }
    }

    private void SystemClicked(GalaxyMapSystemController clickedSystem)
    {
        selectedSystem = clickedSystem;
    }
}
