using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class GalaxyMapController : MonoBehaviour
{
    public GameObject panel;
    public GameObject mapSystemPrefab;
    public float mapScale = 1;

    private Dictionary<string, GameObject> mapSystems = new Dictionary<string, GameObject>();

    void Start()
    {
        foreach (var starSystem in StarSystemScriptableObject.AllSystems())
        {
            Debug.Log($"Adding {starSystem} to map");

            var mapSystem = Instantiate<GameObject>(mapSystemPrefab, panel.transform);
            Debug.Assert(!mapSystems.ContainsKey(starSystem.name));
            mapSystems.Add(starSystem.name, mapSystem);

            var graphic = mapSystem.GetComponent<Graphic>();
            graphic.rectTransform.anchoredPosition = starSystem.galaxyPosition * mapScale;

            var label = mapSystem.GetComponentInChildren<Text>();
            label.text = starSystem.name;
        }
    }

    void Update()
    {
        string currentSystem = SceneManager.GetActiveScene().name;
        foreach (var mapSystem in mapSystems)
        {
            var label = mapSystem.Value.GetComponentInChildren<Text>();
            label.color = (mapSystem.Key == currentSystem ? Color.yellow : Color.white);
        }
    }
}
