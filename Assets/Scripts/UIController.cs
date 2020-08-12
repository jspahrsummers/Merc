using System;
using UnityEngine;
using TMPro;

/// <summary>Responds to UI events.</summary>
public sealed class UIController : MonoBehaviour
{
    [Tooltip("Text for displaying all online players' names.")]
    public TMP_Text onlinePlayerText;

    /// <summary>Input action map for UI controls.</summary>
    private Inputs inputs;

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
        if (onlinePlayerText == null)
        {
            return;
        }

        var onlinePlayers = GameController.Find()?.onlinePlayerList;
        string playersString = "";
        if (onlinePlayers != null)
        {
            playersString = String.Join("\n", onlinePlayers);
        }

        onlinePlayerText.text = $"Players online:\n{playersString}";
    }
}
