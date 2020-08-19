using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>Displays a single system on the galaxy map screen, and handles UI behaviors related to it.</summary>
public sealed class GalaxyMapSystemController : MonoBehaviour
{
    [Tooltip("The text element rendering the name of this system.")]
    public TMP_Text nameText;

    [Tooltip("The map icon for this system.")]
    public Image icon;

    public void SetSelected(bool selected)
    {
        var color = selected ? Color.yellow : Color.white;
        icon.color = color;
        nameText.color = color;
    }
}
