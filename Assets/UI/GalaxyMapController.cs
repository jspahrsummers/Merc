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
    public string selectedSystem { get; private set; }

    void Awake()
    {
        selectedSystem = SceneManager.GetActiveScene().name;
    }

    void OnEnable()
    {
        // HACK: We should not do this every time the map is enabled, but for
        // some reason, selection state breaks without it. (The button will only
        // be selected on first appearance, then be un-selectable in code
        // afterward.)
        foreach (var starSystem in StarSystemScriptableObject.AllSystems())
        {
            var mapSystem = Instantiate<GameObject>(mapSystemPrefab, panel.transform);
            mapSystems.Add(starSystem.name, mapSystem);

            var graphic = mapSystem.GetComponent<Graphic>();
            graphic.rectTransform.anchoredPosition = starSystem.galaxyPosition * mapScale;

            var label = mapSystem.GetComponentInChildren<Text>();
            label.text = starSystem.name;

            var button = mapSystem.GetComponentInChildren<Button>();
            if (starSystem.name == selectedSystem)
            {
                button.Select();
            }

            button.onClick.AddListener(() => SystemClicked(starSystem.name));
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

    private void SystemClicked(string systemName)
    {
        Debug.Assert(mapSystems.ContainsKey(systemName));
        selectedSystem = systemName;
    }
}
