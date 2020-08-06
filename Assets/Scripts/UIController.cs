using UnityEngine;
using UnityEngine.InputSystem;

/// <summary>Responds to UI events.</summary>
public sealed class UIController : MonoBehaviour
{
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
}
