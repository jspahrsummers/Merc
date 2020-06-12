using UnityEngine;
using UnityEngine.UI;

public class UIController : MonoBehaviour
{
    public Slider fuelBar;
    public Text creditsText;
    public PlayerStateScriptableObject playerState;

    // TODO: Reference something else instead of a controller?
    public PlayerShipController playerShipController;

    void Start()
    {
        MercDebug.EnforceField(fuelBar);
        MercDebug.EnforceField(creditsText);
        MercDebug.EnforceField(playerState);
        MercDebug.EnforceField(playerShipController);
    }

    void LateUpdate()
    {
        fuelBar.value = playerShipController.fuel;
        creditsText.text = $"{playerState.credits:#,#} credits";
    }
}
