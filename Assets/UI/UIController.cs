using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UIController : MonoBehaviour
{
    public Slider fuelBar;
    public Text creditsText;
    public PlayerStateScriptableObject playerState;

    // TODO: Reference something else instead of a controller?
    public PlayerShipController playerShipController;

    void LateUpdate()
    {
        fuelBar.value = playerShipController.fuel;
        creditsText.text = $"{playerState.credits:#,#} credits";
    }
}
