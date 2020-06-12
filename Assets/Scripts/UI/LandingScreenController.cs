using UnityEngine;
using UnityEngine.UI;

public sealed class LandingScreenController : MonoBehaviour
{
    public Text welcomeText;
    public TradingUIController tradingUIController;

    private LandedState? landedState;

    public void Prepare(LandedState state)
    {
        landedState = state;
        tradingUIController.Prepare(state);
    }

    public void OnDepart()
    {
        gameObject.SetActive(false);
    }

    void OnEnable()
    {
        MercDebug.Invariant(landedState != null, "Landing state not set before UI controller enabled");

        PlanetScriptableObject planet = landedState.Value.planet;
        welcomeText.text = $"Welcome to {planet.name}";

        tradingUIController.enabled = true;
    }

    void OnDisable()
    {
        landedState = null;
        tradingUIController.enabled = false;
    }
}
