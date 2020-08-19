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
    }
}
