using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using Mirror;

/// <summary>Controls high-level game behaviors on the server, including functionality that spans multiple scenes and players.</summary>
/// <remarks>This class is meant to be server-only, and is effectively a singleton.</remarks>
public sealed class GameController : NetworkBehaviour
{
    [Tooltip("A damageable object to automatically spawn repeatedly, for the player(s) to destroy.")]
    public DamageableController frigatePrefab;

    /// <summary>Spawned objects will be randomly offset between negative and positive values of this number, along X and Y axes.</summary>
    const float RandomTranslationRange = 10;

    /// <summary>The active network manager.</summary>
    private MercNetworkManager networkManager => (MercNetworkManager)NetworkManager.singleton;

    /// <summary>A list of players, to synchronize to clients.</summary>
    public sealed class SyncPlayerList : SyncSortedSet<string> { }

    /// <summary>All players currently connected to this server.</summary>
    public SyncPlayerList onlinePlayerList = new SyncPlayerList();

    public static GameController Find()
    {
        return GameObject.FindWithTag("GameController")?.GetComponent<GameController>();
    }

    public override void OnStartServer()
    {
        networkManager.clientConnectedToServer.AddListener(ClientConnectedToServer);
        networkManager.clientDisconnectedFromServer.AddListener(ClientDisconnectedFromServer);

        LoadAllScenes();
        SpawnFrigate();
    }

    void OnDestroy()
    {
        networkManager?.clientConnectedToServer.RemoveListener(ClientConnectedToServer);
        networkManager?.clientDisconnectedFromServer.RemoveListener(ClientDisconnectedFromServer);
    }

    private void LoadAllScenes()
    {
        var loadedScenes = new HashSet<int>();
        for (int i = 0; i < SceneManager.sceneCount; i++)
        {
            var scene = SceneManager.GetSceneAt(i);
            loadedScenes.Add(scene.buildIndex);
        }

        for (int i = 0; i < SceneManager.sceneCountInBuildSettings; i++)
        {
            if (loadedScenes.Contains(i))
            {
                continue;
            }

            SceneManager.LoadSceneAsync(i, LoadSceneMode.Additive);
        }
    }

    private void ClientConnectedToServer(NetworkConnection connection)
    {
        onlinePlayerList.Add(networkManager.networkAuthenticator.nicknames[connection.connectionId]);
    }

    private void ClientDisconnectedFromServer(NetworkConnection connection)
    {
        string nickname;
        if (!networkManager.networkAuthenticator.nicknames.TryGetValue(connection.connectionId, out nickname))
        {
            return;
        }

        onlinePlayerList.Remove(nickname);
    }

    [Server]
    private void SpawnFrigate()
    {
        var position = new Vector3(Random.Range(-RandomTranslationRange, RandomTranslationRange), Random.Range(-RandomTranslationRange, RandomTranslationRange), 0);
        var rotation = Quaternion.Euler(-90, 0, 0) * Quaternion.AngleAxis(Random.Range(0, 360), Vector3.up);
        var frigate = Instantiate<DamageableController>(frigatePrefab, position, rotation);
        frigate.destroyed.AddListener(FrigateDestroyed);
        SceneManager.MoveGameObjectToScene(frigate.gameObject, gameObject.scene);
        NetworkServer.Spawn(frigate.gameObject);
    }

    /// <summary>Event handler when the spawned frigate has been destroyed by a player.</summary>
    [Server]
    public void FrigateDestroyed(DamageableController controller)
    {
        SpawnFrigate();
    }
}
