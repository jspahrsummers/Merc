using UnityEngine.Events;
using Mirror;

/// <summary>Responsible for authenticating player clients with the server.</summary>
/// <remarks>Currently, "authentication" is just ensuring non-duplicate nicknames.</remarks>
public sealed class MercNetworkAuthenticator : NetworkAuthenticator
{
    /// <summary>The nickname for this client to use with the server. Must be set before authentication begins.</summary>
    public string nickname;

    [System.Serializable]
    public sealed class AuthFailedEvent : UnityEvent<string>
    {
    }

    /// <summary>Invoked on the client if authentication fails, with an optional error message explaining why.</summary>
    public AuthFailedEvent authFailed = new AuthFailedEvent();

    /// <summary>Sent from the client to the server to request authentication.</summary>
    public sealed class AuthRequestMessage : MessageBase
    {
        public string nickname;
    }

    /// <summary>Sent from the server to the client with the result of authentication.</summary>
    public sealed class AuthResponseMessage : MessageBase
    {
        /// <summary>Whether authentication succeeded.</summary>
        public bool success;

        /// <summary>If authentication failed, an error message (if possible).</summary>
        public string errorMessage;
    }

    public override void OnStartServer()
    {
        NetworkServer.RegisterHandler<AuthRequestMessage>(RequestAuthForClient, false);
    }

    public override void OnServerAuthenticate(NetworkConnection conn)
    {
        // This is where we could prompt the client for authentication, but in
        // this case, we rely on the client being proactive via OnClientAuthenticate.
    }

    private void RequestAuthForClient(NetworkConnection conn, AuthRequestMessage msg)
    {
        AuthResponseMessage authResponseMessage = new AuthResponseMessage { success = true };
        conn.Send(authResponseMessage);

        base.OnServerAuthenticated.Invoke(conn);
    }

    public override void OnStartClient()
    {
        NetworkClient.RegisterHandler<AuthResponseMessage>(AuthReceivedFromServer, false);
    }

    public override void OnClientAuthenticate(NetworkConnection conn)
    {
        AuthRequestMessage authRequestMessage = new AuthRequestMessage { nickname = nickname };
        NetworkClient.Send(authRequestMessage);
    }

    private void AuthReceivedFromServer(NetworkConnection conn, AuthResponseMessage msg)
    {
        if (!msg.success)
        {
            authFailed.Invoke(msg.errorMessage);
            return;
        }

        base.OnClientAuthenticated.Invoke(conn);
    }
}
