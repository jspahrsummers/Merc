using UnityEngine;
using UnityEngine.UI;
using TMPro;
using Mirror;

/// <summary>Implements the UI for the main menu.</summary>
public sealed class MainMenuController : MonoBehaviour
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

    [Tooltip("Prefab for the network manager to instantiate, if one does not already exist.")]
    public MercNetworkManager networkManagerPrefab;

    [Tooltip("Displays the version number of the build.")]
    public TMP_Text versionNumberText;

    /// <summary>Key into Unity's PlayerPrefs for remembering the user's nickname.</summary>
    const string NicknamePlayerPrefsKey = "nickname";

    private MercNetworkManager networkManager;
    private MercNetworkAuthenticator networkAuthenticator => networkManager.networkAuthenticator;

    /// <summary>Input action map for UI controls.</summary>
    private Inputs inputs;

    void Awake()
    {
        networkManager = MercNetworkManager.Find();
        if (networkManager == null)
        {
            networkManager = Instantiate<MercNetworkManager>(networkManagerPrefab);
        }
    }

    void Start()
    {
        var savedNickname = PlayerPrefs.GetString(NicknamePlayerPrefsKey);
        if (savedNickname != null && savedNickname.Length > 0)
        {
            nicknameInputField.text = savedNickname;
        }
        else
        {
            nicknameInputField.text = RandomNickname();
        }

        versionNumberText.text = $"{Application.version}\n(Unity version {Application.unityVersion})";
    }

    void OnEnable()
    {
        if (inputs == null)
        {
            inputs = new Inputs();
            inputs.UI.Quit.performed += context => Application.Quit();
        }

        networkManager.clientError.AddListener(ClientConnectionErrorOccurred);
        networkManager.serverError.AddListener(ServerStartErrorOccurred);
        networkAuthenticator.authFailed.AddListener(AuthenticationFailed);
        nicknameInputField.onValueChanged.AddListener(NicknameChanged);
        inputs.UI.Enable();
    }

    void OnDisable()
    {
        inputs.UI.Disable();
        networkManager.clientError.RemoveListener(ClientConnectionErrorOccurred);
        networkManager.serverError.RemoveListener(ServerStartErrorOccurred);
        networkAuthenticator.authFailed.RemoveListener(AuthenticationFailed);
        nicknameInputField.onValueChanged.RemoveListener(NicknameChanged);
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

    private void ClientConnectionErrorOccurred()
    {
        ErrorOccurred("could not connect to server");
    }

    private void ServerStartErrorOccurred()
    {
        ErrorOccurred("could not start server");
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
