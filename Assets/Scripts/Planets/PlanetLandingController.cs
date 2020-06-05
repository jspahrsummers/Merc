using UnityEngine;
using UnityEngine.UI;

public class PlanetLandingController : MonoBehaviour
{
    public Text welcomeText;

    // This is set dynamically based on where the player has chosen to land.
    [HideInInspector]
    public PlanetScriptableObject planet;

    void OnEnable()
    {
        MercDebug.Invariant(planet != null, "Planet needs to be set before landing");
        welcomeText.text = $"Welcome to {planet.name}";
    }

    public void OnDepart()
    {
        gameObject.SetActive(false);
    }
}
