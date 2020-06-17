using UnityEngine;
using UnityEngine.UI;

public sealed class UIController : MonoBehaviour
{
    public Slider fuelBar;
    public Text creditsText;
    public PlayerStateScriptableObject playerState;

    [HideInInspector]
    // TODO: Reference something else instead of a controller?
    public PlayerShipController playerShipController;

    void Start()
    {
        MercDebug.EnforceField(fuelBar);
        MercDebug.EnforceField(creditsText);
        MercDebug.EnforceField(playerState);
    }

    void LateUpdate()
    {
        if (playerShipController != null)
        {
            fuelBar.value = playerShipController.fuel;
        }

        creditsText.text = $"{playerState.credits:#,#} credits";
    }
}
