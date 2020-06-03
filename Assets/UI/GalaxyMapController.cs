using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public sealed class GalaxyMapController : MonoBehaviour
{
    public GameObject panel;
    public GameObject mapSystemPrefab;
    public float mapScale = 1;

    private Dictionary<string, GameObject> mapSystems = new Dictionary<string, GameObject>();
    private string selectedSystem;

    void Awake()
    {
        selectedSystem = SceneManager.GetActiveScene().name;
    }

    void OnEnable()
    {
        // HACK: We should not do this every time the map is enabled, but for some reason, selection state breaks without it.
        foreach (var starSystem in StarSystemScriptableObject.AllSystems())
        {
            Debug.Log($"Adding {starSystem} to map");

            var mapSystem = Instantiate<GameObject>(mapSystemPrefab, panel.transform);
            mapSystems.Add(starSystem.name, mapSystem);

            var graphic = mapSystem.GetComponent<Graphic>();
            graphic.rectTransform.anchoredPosition = starSystem.galaxyPosition * mapScale;

            var label = mapSystem.GetComponentInChildren<Text>();
            label.text = starSystem.name;

            if (starSystem.name == selectedSystem)
            {
                var button = mapSystem.GetComponentInChildren<Button>();
                button.Select();
            }
        }

        Debug.Assert(mapSystems.ContainsKey(selectedSystem));
    }

    void OnDisable()
    {
        foreach (var mapSystem in mapSystems.Values)
        {
            Destroy(mapSystem.gameObject);
        }

        mapSystems.Clear();
    }
}
