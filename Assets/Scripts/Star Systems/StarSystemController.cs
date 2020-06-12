using System.Collections.Generic;
using UnityEngine;

public sealed class StarSystemController : MonoBehaviour
{
    [Tooltip("Game object describing this star system")]
    public StarSystemScriptableObject starSystem;

    [Tooltip("The planet objects in the scene, which must match up with the star system's planets")]
    public List<PlanetController> planets = new List<PlanetController>();

    private PlanetController selectedPlanetController;
    public PlanetScriptableObject selectedPlanet => selectedPlanetController?.planet;

    void Start()
    {
        MercDebug.EnforceField(starSystem);

        // TODO: Check planet controllers against star system planets

        foreach (var planetController in planets)
        {
            planetController.selectedEvent.AddListener(OnPlanetSelected);
        }
    }

    public void OnPlanetSelected(PlanetController planetController)
    {
        Debug.Log($"{planetController.planet} clicked");

        Debug.Assert(planets.Contains(planetController));
        selectedPlanetController = planetController;

        foreach (var otherController in planets)
        {
            if (otherController == planetController)
            {
                continue;
            }

            otherController.selected = false;
        }
    }
}
