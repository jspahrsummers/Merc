using UnityEngine;
using UnityEngine.UI;
using TMPro;
using Mirror;

/// <summary>Implements the UI for the main menu.</summary>
public sealed class MainMenuController : NetworkBehaviour
{
    [Tooltip("Field to specify a hostname to connect to.")]
    public TMP_InputField hostnameInputField;

    [Tooltip("Button for connecting to the entered hostname.")]
    public Button connectButton;

    [Tooltip("The text element of the connectButton.")]
    public TMP_Text connectButtonText;

    [Tooltip("Button for starting to host a game.")]
    public Button startGameButton;

    [Tooltip("The text element of the startGameButton.")]
    public TMP_Text startGameButtonText;

    [Tooltip("Field for the player to enter the nickname they want to use.")]
    public TMP_InputField nicknameInputField;

    [Tooltip("Label for showing an error, if one occurred.")]
    public TMP_Text errorLabel;

    [Tooltip("The authenticator to set up prior to trying to connect.")]
    public MercNetworkAuthenticator networkAuthenticator;

    /// <summary>Key into Unity's PlayerPrefs for remembering the user's nickname.</summary>
    const string NicknamePlayerPrefsKey = "nickname";

    void Start()
    {
        networkAuthenticator.authFailed.AddListener(AuthenticationFailed);

        var savedNickname = PlayerPrefs.GetString(NicknamePlayerPrefsKey);
        if (savedNickname != null && savedNickname.Length > 0)
        {
            nicknameInputField.text = savedNickname;
        }
        else
        {
            nicknameInputField.text = RandomNickname();
        }

        nicknameInputField.onValueChanged.AddListener(NicknameChanged);
    }

    private string RandomNickname()
    {
        var suggestions = new string[] {
            "Kraken",
            "Orca",
            "Bowhead",
            "Rorqual",
            "Dolphin",
            "Narwhal",
            "Beluga",
            "Porpoise",
            "Squid",
            "Octopus",
            "Nautilus",
        };

        var selection = new System.Random().Next(0, suggestions.Length);
        return suggestions[selection];
    }

    /// <summary>Connects to the hostname provided as input by the user.</summary>
    public void Connect()
    {
        errorLabel.gameObject.SetActive(false);
        connectButton.enabled = false;
        connectButtonText.text = "Connecting...";
        startGameButton.enabled = false;

        if (hostnameInputField.text.Length == 0)
        {
            ErrorOccurred("no hostname specified");
            return;
        }

        networkAuthenticator.nickname = nicknameInputField.text;
        NetworkManager.singleton.networkAddress = hostnameInputField.text;
        NetworkManager.singleton.StartClient();
    }

    /// <summary>Begins hosting a game (i.e., server + client).</summary>
    public void StartHostGame()
    {
        errorLabel.gameObject.SetActive(false);
        connectButton.enabled = false;
        startGameButton.enabled = false;
        startGameButtonText.text = "Starting...";

        if (nicknameInputField.text.Length == 0)
        {
            ErrorOccurred("no nickname specified");
            return;
        }

        networkAuthenticator.nickname = nicknameInputField.text;
        NetworkManager.singleton.StartHost();
    }

    private void NicknameChanged(string value)
    {
        PlayerPrefs.SetString(NicknamePlayerPrefsKey, value);
    }

    private void ErrorOccurred(string message)
    {
        connectButton.enabled = true;
        connectButtonText.text = "Connect";
        startGameButton.enabled = true;
        startGameButtonText.text = "Start Game";

        errorLabel.text = $"Error: {message}";
        errorLabel.gameObject.SetActive(true);
    }

    private void AuthenticationFailed(string message)
    {
        ErrorOccurred(message);
    }
}
