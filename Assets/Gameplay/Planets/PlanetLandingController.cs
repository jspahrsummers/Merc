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
        welcomeText.text = $"Welcome to {planet.name}";
    }

    public void OnDepart()
    {
        gameObject.SetActive(false);
    }
}
