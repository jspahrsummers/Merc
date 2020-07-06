using UnityEngine;
using UnityEngine.UI;

public sealed class UIController : MonoBehaviour
{
    public Slider fuelBar;
    public Text creditsText;

    [HideInInspector]
    // TODO: Reference something else instead of a controller?
    public PlayerShipController playerShipController;

    private PlayerState playerState => playerShipController.playerState;

    void Start()
    {
        MercDebug.EnforceField(fuelBar);
        MercDebug.EnforceField(creditsText);
    }

    void LateUpdate()
    {
        if (playerShipController == null)
        {
            return;
        }

        fuelBar.value = playerShipController.fuel;
        creditsText.text = $"{playerState.credits:#,#} credits";
    }
}
