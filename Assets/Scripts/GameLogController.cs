using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>Presents scrolling log messages to the user.</summary>
public sealed class GameLogController : MonoBehaviour
{
    [Tooltip("The text of the log.")]
    public TMP_Text logText;

    [Tooltip("The scrolling view containing the log.")]
    public ScrollRect scrollRect;

    /// <summary>Y velocity at which to automatically scroll the view when a new message appears.</summary>
    const float NewMessageScrollVelocity = 100f;

    /// <summary>How many seconds to wait after the most recent log message, before fading out.</summary>
    const float FadeOutDelay = 2f;

    /// <summary>How many points of alpha to subtract per second during fade out.</summary>
    const float FadeOutRate = 0.3f;

    /// <summary>Alpha value to fade text out to.</summary>
    const float FadeOutAlpha = 0.4f;

    /// <summary>Coroutine for the fade out animation, so it can be cancelled.</summary>
    private Coroutine fadeOutCoroutine;

    void Start()
    {
        logText.text = "";
    }

    /// <summary>Adds a new message to the tip of the log.</summary>
    public void AddMessage(string message)
    {
        if (logText.text.Length > 0)
        {
            message = "\n" + message;
        }

        logText.text += message;
        scrollRect.velocity = new Vector2(0, NewMessageScrollVelocity);
        StartFadeOut();
    }

    private void StartFadeOut()
    {
        if (fadeOutCoroutine != null)
        {
            StopCoroutine(fadeOutCoroutine);
        }

        logText.color = Color.white;
        fadeOutCoroutine = StartCoroutine(FadeOutAfterDelay());
    }

    private IEnumerator FadeOutAfterDelay()
    {
        yield return new WaitForSeconds(FadeOutDelay);

        Color color;
        do
        {
            yield return new WaitForEndOfFrame();

            color = logText.color;
            color.a = Mathf.MoveTowards(color.a, FadeOutAlpha, FadeOutRate * Time.deltaTime);
            logText.color = color;
        } while (color.a > FadeOutAlpha);
    }
}
