using System;
using System.Collections;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;
using TMPro;
using Mirror;

/// <summary>Responds to UI events and controls the in-game UI.</summary>
public sealed class UIController : MonoBehaviour
{
    [Tooltip("Text for displaying all online players' names.")]
    public TMP_Text onlinePlayerText;

    [Tooltip("Frames per second counter and ping text.")]
    public TMP_Text fpsCounterAndPing;

    [Tooltip("Displays how much energy the player's ship has.")]
    public Slider energyBar;

    [Tooltip("Displays how much hull strength the player's ship has remaining.")]
    public Slider hullBar;

    [Tooltip("Displays how much shield strength the player's ship has remaining.")]
    public Slider shieldsBar;

    [Tooltip("Activated when the player lands on a planet.")]
    public LandingScreenController landingScreen;

    [Tooltip("Map overlay when the player wants to view nearby systems and hyperspace routes.")]
    public GalaxyMapController galaxyMap;

    [Tooltip("Scrolling game log that any game object can add a message to.")]
    public GameLogController gameLog;

    /// <summary>How many seconds should pass between updates to the FPS counter and ping text.</summary>
    const float FPSCounterUpdateRate = 0.5f;

    /// <summary>Input action map for UI controls.</summary>
    private Inputs inputs;

    /// <summary>Coroutine for updating the FPS counter and ping text.</summary>
    private Coroutine fpsCounterCoroutine;

    /// <summary>Returns the UIController in the current scene, if available.</summary>
    public static UIController Find()
    {
        return GameObject.FindWithTag("UIController")?.GetComponent<UIController>();
    }

    public void ShowLandingScreen(PlanetController planet, UnityAction dismissedCallback)
    {
        landingScreen.planet = planet;
        landingScreen.gameObject.SetActive(true);

        // LandingScreenController will clear this listener once it's dismissed.
        landingScreen.dismissed.AddListener(dismissedCallback);
    }

    void OnEnable()
    {
        if (inputs == null)
        {
            inputs = new Inputs();
            inputs.UI.GalaxyMap.performed += context => ToggleGalaxyMap();
            inputs.UI.Quit.performed += context => Application.Quit();
        }

        inputs.UI.Enable();

        fpsCounterAndPing.text = "";
        fpsCounterCoroutine = StartCoroutine(RunFPSCounter());
    }

    void OnDisable()
    {
        inputs.UI.Disable();

        if (fpsCounterCoroutine != null)
        {
            StopCoroutine(fpsCounterCoroutine);
            fpsCounterCoroutine = null;
        }
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

    private IEnumerator RunFPSCounter()
    {
        while (true)
        {
            var startFrameCount = Time.frameCount;
            var startTime = Time.unscaledTime;

            yield return new WaitForSecondsRealtime(FPSCounterUpdateRate);

            var endFrameCount = Time.frameCount;
            var endTime = Time.unscaledTime;

            int fps = (int)((endFrameCount - startFrameCount) / (endTime - startTime));
            if (NetworkManager.singleton.mode == NetworkManagerMode.ClientOnly)
            {
                int pingMs = (int)Math.Round(NetworkTime.rtt * 1000);
                fpsCounterAndPing.text = $"{fps} FPS\n{pingMs}ms ping";
            }
            else
            {
                fpsCounterAndPing.text = $"{fps} FPS";
            }
        }
    }

    private void ToggleGalaxyMap()
    {
        // Unlike the landing screen, this purposely does not block player input, because the player has not been taken anywhere else--they are still active in exactly the same position as before.
        galaxyMap.gameObject.SetActive(!galaxyMap.gameObject.activeSelf);
    }
}
