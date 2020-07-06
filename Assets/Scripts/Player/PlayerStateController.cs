using System;
using System.Collections.Generic;
using UnityEngine;
using Mirror;

/// <summary>Stores and manages the state associated with a specific player's game, including offline persistence.</summary>
/// <remarks>This object only exists on the server (where it is authoritative) and the particular client whose state it concerns.</remarks>
public sealed class PlayerStateController : NetworkVisibility
{
    [HideInInspector]
    public PlayerState playerState;

    public override bool OnCheckObserver(NetworkConnection connection)
    {
        return connection.authenticationData == playerState;
    }

    public override void OnRebuildObservers(HashSet<NetworkConnection> observers, bool initialize)
    {
        foreach (NetworkConnectionToClient connection in NetworkServer.connections.Values)
        {
            if (connection.authenticationData != playerState)
            {
                continue;
            }

            observers.Add(connection);
        }
    }

    public override void OnStartClient()
    {
        MercDebug.Invariant(playerState == NetworkClient.connection.authenticationData, $"Expected player state {playerState} to match local authentication data {NetworkClient.connection.authenticationData}");
    }
}
