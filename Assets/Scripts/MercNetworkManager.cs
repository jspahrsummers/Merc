using UnityEngine;
using UnityEngine.Events;
using Mirror;

/// <summary>Custom NetworkManager type that supports listeners for the default "callbacks."</summary>
public sealed class MercNetworkManager : NetworkManager
{
    /// <summary>An event tagged with a network connection that it happened to/on.</summary>
    public sealed class NetworkConnectionEvent : UnityEvent<NetworkConnection> { }

    [Tooltip("Event invoked when this client successfully connects to a server.")]
    public UnityEvent clientConnected = new UnityEvent();

    [Tooltip("Event invoked when this client encounters a network error.")]
    public UnityEvent clientError = new UnityEvent();

    [Tooltip("Event invoked when this sever encounters a network error.")]
    public UnityEvent serverError = new UnityEvent();

    [Tooltip("Event invoked when a client successfully connects to this server.")]
    public NetworkConnectionEvent clientConnectedToServer = new NetworkConnectionEvent();

    [Tooltip("Event invoked when a client disconnects from this server.")]
    public NetworkConnectionEvent clientDisconnectedFromServer = new NetworkConnectionEvent();

    [Tooltip("The authenticator to use for connections via this network manager.")]
    public MercNetworkAuthenticator networkAuthenticator;

    public static MercNetworkManager Find()
    {
        return (MercNetworkManager)NetworkManager.singleton;
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

    public override void OnServerConnect(NetworkConnection connection)
    {
        base.OnServerConnect(connection);
        clientConnectedToServer.Invoke(connection);
    }

    public override void OnServerDisconnect(NetworkConnection connection)
    {
        base.OnServerDisconnect(connection);
        clientDisconnectedFromServer.Invoke(connection);
    }
}
