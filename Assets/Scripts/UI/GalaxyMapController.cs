using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public sealed class GalaxyMapController : MonoBehaviour
{
    public GameObject panel;
    public GalaxyMapSystemController mapSystemPrefab;

    private Dictionary<string, GalaxyMapSystemController> mapSystems = new Dictionary<string, GalaxyMapSystemController>();
    public string selectedSystem { get; private set; }

    void Awake()
    {
        selectedSystem = SceneManager.GetActiveScene().name;
    }

    void Start()
    {
        MercDebug.EnforceField(panel);
        MercDebug.EnforceField(mapSystemPrefab);
    }

    void OnEnable()
    {
        // HACK: We should not do this every time the map is enabled, but for
        // some reason, selection state breaks without it. (The button will only
        // be selected on first appearance, then be un-selectable in code
        // afterward.)
        foreach (var starSystem in StarSystemScriptableObject.AllSystems())
        {
            var mapSystemController = Instantiate<GalaxyMapSystemController>(mapSystemPrefab, panel.transform);
            mapSystems.Add(starSystem.name, mapSystemController);

            mapSystemController.starSystem = starSystem;
            if (starSystem.name == selectedSystem)
            {
                mapSystemController.Select();
            }

            mapSystemController.clickedEvent.AddListener(SystemClicked);
        }

        MercDebug.Invariant(mapSystems.ContainsKey(selectedSystem), $"Could not find {selectedSystem} in all systems");
    }

    void OnDisable()
    {
        foreach (var mapSystem in mapSystems.Values)
        {
            Destroy(mapSystem.gameObject);
        }

        mapSystems.Clear();
    }

    private void SystemClicked(StarSystemScriptableObject starSystem)
    {
        Debug.Assert(mapSystems.ContainsKey(starSystem.name));
        selectedSystem = starSystem.name;
    }
}
