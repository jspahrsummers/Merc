using UnityEngine;
using UnityEngine.UI;

public class GalaxyMapController : MonoBehaviour
{
    public GameObject panel;
    public GameObject mapSystemPrefab;
    public float mapScale = 1;

    void Start()
    {
        var starSystems = StarSystemScriptableObject.AllSystems();
        foreach (var starSystem in starSystems)
        {
            Debug.Log($"Adding {starSystem} to map");

            var mapSystem = Instantiate<GameObject>(mapSystemPrefab, panel.transform);

            var graphic = mapSystem.GetComponent<Graphic>();
            graphic.rectTransform.anchoredPosition = starSystem.galaxyPosition * mapScale;

            var label = mapSystem.GetComponentInChildren<Text>();
            label.text = starSystem.name;
        }
    }
}
