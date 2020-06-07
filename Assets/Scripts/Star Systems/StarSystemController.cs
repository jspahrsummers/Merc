using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public sealed class StarSystemController : MonoBehaviour
{
    public StarSystemScriptableObject starSystem;

    private List<PlanetController> planetControllers = new List<PlanetController>();
    private PlanetController selectedPlanetController;
    public PlanetScriptableObject selectedPlanet => selectedPlanetController?.planet;

    public void AddPlanetController(PlanetController planetController)
    {
        Debug.Assert(!planetControllers.Contains(planetController));
        planetControllers.Add(planetController);
    }

    public void OnPlanetSelected(PlanetController planetController)
    {
        Debug.Log($"{planetController.planet} clicked");

        Debug.Assert(planetControllers.Contains(planetController));
        selectedPlanetController = planetController;

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
