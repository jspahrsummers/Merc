using Mirror;

public static class NetworkBehaviourExtensions
{
    public static bool IsServerOrHasAuthority(this NetworkBehaviour behaviour)
    {
        return behaviour.hasAuthority || behaviour.isServer;
    }
}
