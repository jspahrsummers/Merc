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

    public override void OnClientConnect(NetworkConnection connection)
    {
        clientConnected.Invoke();
    }

    public override void OnClientError(NetworkConnection connection, int errorCode)
    {
        clientError.Invoke();
    }

    public override void OnServerError(NetworkConnection connection, int errorCode)
    {
        serverError.Invoke();
    }
}
