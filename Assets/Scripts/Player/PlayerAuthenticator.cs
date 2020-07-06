using Mirror;

public sealed class PlayerAuthenticator : NetworkAuthenticator
{
    public sealed class AuthRequestMessage : MessageBase
    {
        public string username;
    }

    public sealed class AuthResponseMessage : MessageBase
    {
        public PlayerState playerState;
    }

    public override void OnStartServer()
    {
        NetworkServer.RegisterHandler<AuthRequestMessage>(OnAuthRequestMessage, false);
    }

    public override void OnServerAuthenticate(NetworkConnection connection) { }

    public void OnAuthRequestMessage(NetworkConnection connection, AuthRequestMessage request)
    {
        var playerState = new PlayerState { username = request.username };
        var response = new AuthResponseMessage();
        response.playerState = playerState;

        connection.authenticationData = playerState;
        connection.Send(response);

        base.OnServerAuthenticated.Invoke(connection);
    }

    public override void OnStartClient()
    {
        NetworkClient.RegisterHandler<AuthResponseMessage>(OnAuthResponseMessage, false);
    }

    public override void OnClientAuthenticate(NetworkConnection connection)
    {
        AuthRequestMessage request = new AuthRequestMessage();
        request.username = "foobar";
        NetworkClient.Send(request);
    }

    public void OnAuthResponseMessage(NetworkConnection connection, AuthResponseMessage response)
    {
        connection.authenticationData = response.playerState;
        base.OnClientAuthenticated.Invoke(connection);
    }
}
