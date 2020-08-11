using UnityEngine;
using UnityEngine.Events;
using Mirror;

/// <summary>Custom NetworkManager type that supports listeners for the default "callbacks."</summary>
public sealed class MercNetworkManager : NetworkManager
{
    [Tooltip("Event invoked when this client successfully connects to a server.")]
    public UnityEvent clientConnected = new UnityEvent();

    [Tooltip("Event invoked when this client encounters a network error.")]
    public UnityEvent clientError = new UnityEvent();

    [Tooltip("Event invoked when this sever encounters a network error.")]
    public UnityEvent serverError = new UnityEvent();

    [Tooltip("The authenticator to use for connections via this network manager.")]
    public MercNetworkAuthenticator networkAuthenticator;

    /// <summary>The scene that this object was spawned in.</summary>
    private string spawnScene;

    public override void Awake()
    {
        // Retrieve this before moved to special "DontDestroyOnLoad" scene
        spawnScene = gameObject.scene.path;

        base.Awake();
    }

    public override void Start()
    {
        base.Start();

        // Convenience for testing in the Unity Editor: automatically start host when running any scene different from the default "offline" scene
        if (spawnScene != offlineScene && mode == NetworkManagerMode.Offline)
        {
            Debug.Log($"Automatically starting host for debugging purposes (scene: {spawnScene})");
            networkAuthenticator.nickname = "Tester";
            onlineScene = null;
            StartHost();
        }
    }

    // Invoked on the client after authenticating successfully to the server.
    public override void OnClientConnect(NetworkConnection connection)
    {
        base.OnClientConnect(connection);
        clientConnected.Invoke();
    }

    public override void OnClientError(NetworkConnection connection, int errorCode)
    {
        base.OnClientError(connection, errorCode);
        clientError.Invoke();
    }

    public override void OnServerError(NetworkConnection connection, int errorCode)
    {
        base.OnServerError(connection, errorCode);
        serverError.Invoke();
    }
}
