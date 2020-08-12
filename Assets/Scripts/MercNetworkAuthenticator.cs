using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Events;
using Mirror;

/// <summary>On the server, saved into NetworkConnection.authenticationData for later reference during gameplay.</summary>
public sealed class MercAuthenticationData
{
    /// <summary>The nickname that this user connected with.</summary>
    public string nickname;
}

/// <summary>Responsible for authenticating player clients with the server.</summary>
/// <remarks>Currently, "authentication" is just ensuring non-duplicate nicknames.</remarks>
public sealed class MercNetworkAuthenticator : NetworkAuthenticator
{
    [Tooltip("The nickname for this client to use with the server. Must be set before authentication begins.")]
    public string nickname;

    [Tooltip("Invoked on the client if authentication succeeds.")]
    public UnityEvent authSucceeded = new UnityEvent();

    [Tooltip("A file containing the semantic version of the project.")]
    public TextAsset versionText;

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

    /// <summary>Nicknames by connection ID, tracked on the server.</summary>
    private Dictionary<int, string> nicknames = new Dictionary<int, string>();

    void Start()
    {
        if (versionText.text.Trim() != Application.version.Trim())
        {
            Debug.LogWarning($"Version file \"{versionText}\" does not match project settings version \"{Application.version}\"");
        }
    }

    public override void OnStartServer()
    {
        NetworkServer.RegisterHandler<AuthRequestMessage>(RequestAuthForClient, false);
    }

    public override void OnServerAuthenticate(NetworkConnection connection)
    {
        // This is where we could prompt the client for authentication, but in
        // this case, we rely on the client being proactive via OnClientAuthenticate.
    }

    private void RequestAuthForClient(NetworkConnection connection, AuthRequestMessage msg)
    {
        PruneDisconnected();

        AuthResponseMessage errorResponse = null;
        if (msg.nickname.Length == 0)
        {
            errorResponse = new AuthResponseMessage { success = false, errorMessage = $"Nickname cannot be empty" };
        }
        else if (nicknames.ContainsValue(msg.nickname))
        {
            errorResponse = new AuthResponseMessage { success = false, errorMessage = $"Nickname \"{msg.nickname}\" is already taken on this server" };
        }
        else if (nicknames.ContainsKey(connection.connectionId))
        {
            errorResponse = new AuthResponseMessage { success = false, errorMessage = $"Client already connected!" };
        }

        if (errorResponse != null)
        {
            Debug.Log($"Rejecting attempted auth for \"{msg.nickname}\": {errorResponse.errorMessage}");
            connection.Send(errorResponse);
            return;
        }

        var authData = new MercAuthenticationData { nickname = msg.nickname };
        Debug.Log($"\"{authData.nickname}\" connected");
        nicknames.Add(connection.connectionId, authData.nickname);

        connection.authenticationData = authData;
        connection.Send(new AuthResponseMessage { success = true });
        base.OnServerAuthenticated.Invoke(connection);
    }

    /// <summary>Removes tracked data for client connections that are no longer present.</summary>
    private void PruneDisconnected()
    {
        foreach (var key in nicknames.Keys.ToList())
        {
            if (!NetworkServer.connections.ContainsKey(key))
            {
                nicknames.Remove(key);
            }
        }
    }

    public override void OnStartClient()
    {
        NetworkClient.RegisterHandler<AuthResponseMessage>(AuthReceivedFromServer, false);
    }

    public override void OnClientAuthenticate(NetworkConnection connection)
    {
        Debug.Log($"Sending authentication request as \"{nickname}\"");
        AuthRequestMessage authRequestMessage = new AuthRequestMessage { nickname = nickname };
        NetworkClient.Send(authRequestMessage);
    }

    private void AuthReceivedFromServer(NetworkConnection connection, AuthResponseMessage msg)
    {
        if (!msg.success)
        {
            Debug.Log($"Authentication failure: {msg.errorMessage}");
            authFailed.Invoke(msg.errorMessage);
            NetworkManager.singleton.StopClient();
            return;
        }

        Debug.Log($"Authentication succeeded");
        base.OnClientAuthenticated.Invoke(connection);
    }
}
