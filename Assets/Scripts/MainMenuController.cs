using System;
using UnityEngine;
using TMPro;
using Mirror;

/// <summary>Implements the UI for the main menu.</summary>
public sealed class MainMenuController : MonoBehaviour
{
    [Tooltip("Field to specify a hostname to connect to.")]
    public TMP_InputField hostnameInputField;

    [Tooltip("Field for the player to enter the nickname they want to use.")]
    public TMP_InputField nicknameInputField;

    /// <summary>Connects to the hostname provided as input by the user.</summary>
    public void Connect()
    {
        Uri uri;
        try
        {
            uri = new Uri(hostnameInputField.text);
        }
        catch (UriFormatException exception)
        {
            return;
        }

        NetworkManager.singleton.StartClient(uri);
    }

    /// <summary>Begins hosting a game (i.e., server + client).</summary>
    public void StartHostGame()
    {
        NetworkManager.singleton.StartHost();
    }
}
