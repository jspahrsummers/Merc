using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using Mirror;

/// <summary>Controls high-level game behaviors, including functionality that spans multiple scenes and players.</summary>
/// <remarks>This class will also spawn a NetworkManager and start it in host mode if one does not exist yet. This is a convenience for dev-time testing, as usually the network manager is created on the main menu before the GameController is instantiated.</remarks>
public sealed class GameController : NetworkBehaviour
{
    [Tooltip("Prefab for spawning the network manager, if it does not already exist.")]
    public MercNetworkManager networkManagerPrefab;

    /// <summary>The active network manager.</summary>
    private MercNetworkManager networkManager;

    /// <summary>A list of players, to synchronize to clients.</summary>
    public sealed class SyncPlayerList : SyncSortedSet<string> { }

    /// <summary>All players currently connected to this server.</summary>
    public SyncPlayerList onlinePlayerList = new SyncPlayerList();

    public static GameController Find()
    {
        return GameObject.FindWithTag("GameController")?.GetComponent<GameController>();
    }

    void Awake()
    {
        Debug.Log($"GameController awake");

        networkManager = MercNetworkManager.Find();
        if (networkManager == null)
        {
            networkManager = Instantiate<MercNetworkManager>(networkManagerPrefab);
            Debug.Log($"Automatically starting host for debugging purposes (scene: {gameObject.scene})");

            networkManager.networkAuthenticator.nickname = "Tester";
            networkManager.StartHost();
        }
    }

    public override void OnStartServer()
    {
        foreach (var nickname in networkManager.networkAuthenticator.nicknames.Values)
        {
            onlinePlayerList.Add(nickname);
        }

        networkManager.clientConnectedToServer.AddListener(ClientConnectedToServer);
        networkManager.clientDisconnectedFromServer.AddListener(ClientDisconnectedFromServer);

        LoadAllScenes();
    }

    void OnDestroy()
    {
        networkManager?.clientConnectedToServer.RemoveListener(ClientConnectedToServer);
        networkManager?.clientDisconnectedFromServer.RemoveListener(ClientDisconnectedFromServer);
    }

    [Server]
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

            Debug.Log($"Preloading scene at build index {i}");
            SceneManager.LoadSceneAsync(i, LoadSceneMode.Additive);
        }
    }

    [Server]
    private void ClientConnectedToServer(NetworkConnection connection)
    {
        onlinePlayerList.Add(networkManager.networkAuthenticator.nicknames[connection.connectionId]);
    }

    [Server]
    private void ClientDisconnectedFromServer(NetworkConnection connection)
    {
        string nickname;
        if (!networkManager.networkAuthenticator.nicknames.TryGetValue(connection.connectionId, out nickname))
        {
            return;
        }

        onlinePlayerList.Remove(nickname);
    }
}
