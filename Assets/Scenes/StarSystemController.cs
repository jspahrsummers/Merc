using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public sealed class StarSystemController : MonoBehaviour
{
    public StarSystemScriptableObject starSystem;
    public GameObject hyperspaceArrivalPrefab;

    private List<PlanetController> planetControllers = new List<PlanetController>();
    private PlanetController selectedPlanet;

    public void JumpToSystem(StarSystemScriptableObject newSystem)
    {
        StartCoroutine(LoadSystemAsync(newSystem));
    }

    private IEnumerator LoadSystemAsync(StarSystemScriptableObject newSystem)
    {
        AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(newSystem.name);
        asyncLoad.allowSceneActivation = false;

        while (!asyncLoad.isDone)
        {
            if (asyncLoad.progress >= 0.9f)
            {
                GameObject arrival = Instantiate(hyperspaceArrivalPrefab);
                var arrivalController = arrival.GetComponent<HyperspaceArrivalController>();
                arrivalController.arrivalAngle = starSystem.AngleToSystem(newSystem);
                DontDestroyOnLoad(arrival);

                asyncLoad.allowSceneActivation = true;
            }

            yield return null;
        }
    }

    public void AddPlanetController(PlanetController planetController)
    {
        Debug.Assert(!planetControllers.Contains(planetController));
        planetControllers.Add(planetController);
    }

    public void OnPlanetSelected(PlanetController planetController)
    {
        Debug.Log($"{planetController.planet} clicked");

        Debug.Assert(planetControllers.Contains(planetController));
        selectedPlanet = planetController;

        foreach (var otherController in planetControllers)
        {
            if (otherController == planetController)
            {
                continue;
            }

            otherController.selected = false;
        }
    }
}
