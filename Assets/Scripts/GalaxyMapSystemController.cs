using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;
using TMPro;

/// <summary>Fires when the user clicks a GalaxyMapSystemController.</summary>
public sealed class GalaxyMapSystemClickedEvent : UnityEvent<GalaxyMapSystemController> { }

/// <summary>Displays a single system on the galaxy map screen, and handles UI behaviors related to it.</summary>
public sealed class GalaxyMapSystemController : MonoBehaviour
{
    [Tooltip("The text element rendering the name of this system.")]
    public TMP_Text nameText;

    [Tooltip("The map icon for this system.")]
    public Image icon;

    [Tooltip("Invoked when this system's UI is clicked by the user.")]
    public GalaxyMapSystemClickedEvent clicked = new GalaxyMapSystemClickedEvent();

    private bool _currentSystem = false;

    /// <summary>Whether this is the system that the player is currently located in.</summary>
    public bool currentSystem
    {
        get => _currentSystem;
        set
        {
            _currentSystem = value;
            Rerender();
        }
    }

    private bool _selected = false;

    /// <summary>Whether the user has selected this system.</summary>
    public bool selected
    {
        get => _selected;
        set
        {
            _selected = value;
            Rerender();
        }
    }

    void OnEnable()
    {
        Rerender();
    }

    private void Rerender()
    {
        Color color;
        if (currentSystem)
        {
            color = Color.cyan;
        }
        else if (selected)
        {
            color = Color.yellow;
        }
        else
        {
            color = Color.white;
        }

        icon.color = color;
        nameText.color = color;
    }

    public void Click()
    {
        clicked.Invoke(this);
    }
}
