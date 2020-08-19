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

    public void SetSelected(bool selected)
    {
        var color = selected ? Color.yellow : Color.white;
        icon.color = color;
        nameText.color = color;
    }

    public void Click()
    {
        clicked.Invoke(this);
    }
}
