using System;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>Responds to UI events and controls the in-game UI.</summary>
public sealed class UIController : MonoBehaviour
{
    [Tooltip("Text for displaying all online players' names.")]
    public TMP_Text onlinePlayerText;

    [Tooltip("Displays how much energy the player's ship has.")]
    public Slider energyBar;

    /// <summary>Input action map for UI controls.</summary>
    private Inputs inputs;

    /// <summary>Returns the UIController in the current scene, if available.</summary>
    public static UIController Find()
    {
        return GameObject.FindWithTag("UIController")?.GetComponent<UIController>();
    }

    void OnEnable()
    {
        if (inputs == null)
        {
            inputs = new Inputs();
            inputs.UI.Quit.performed += context => Application.Quit();
        }

        inputs.UI.Enable();
    }

    void OnDisable()
    {
        inputs.UI.Disable();
    }

    void Update()
    {
        var onlinePlayers = GameController.Find()?.onlinePlayerList;
        string playersString = "";
        if (onlinePlayers != null)
        {
            playersString = String.Join("\n", onlinePlayers);
        }

        onlinePlayerText.text = $"Players online:\n{playersString}";
    }
}
