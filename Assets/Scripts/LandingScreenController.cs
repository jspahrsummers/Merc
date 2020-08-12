using UnityEngine;
using UnityEngine.Events;
using TMPro;

/// <summary>Presents the UI for planet-side things to do.</summary>
public sealed class LandingScreenController : MonoBehaviour
{
    [Tooltip("The planet landed upon. Must be set before this controller is enabled.")]
    public PlanetController planet;

    [Tooltip("Title text for the landing screen.")]
    public TMP_Text welcomeText;

    [Tooltip("Invoked when the landing screen is dismissed by the user.")]
    public UnityEvent dismissed = new UnityEvent();

    void OnEnable()
    {
        welcomeText.text = $"Welcome to {planet.name}!";
    }

    public void DepartClicked()
    {
        dismissed.Invoke();
        Destroy(gameObject);
    }
}
