using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using Mirror;
using MercExtensions;

/// <summary>Sent from the client to the server when a scene has been loaded, but not yet activated, to allow the server to issue the next instruction.</summary>
internal sealed class SceneReadyMessage : MessageBase
{
    /// <summary>The scene that was loaded.</summary>
    public string sceneNameOrPath;
}

/// <summary>Sent from the server to the client, instructing it to activate a specific scene. The scene must have been loaded, but not already activated.</summary>
internal sealed class ActivateSceneMessage : MessageBase
{
    /// <summary>The scene to activate.</summary>
    public string sceneNameOrPath;
}

/// <summary>A list of players, to synchronize to clients.</summary>
public sealed class SyncPlayerList : SyncSortedSet<string> { }

/// <summary>Controls high-level game behaviors, including functionality that spans multiple scenes and players.</summary>
/// <remarks>This class will also spawn a NetworkManager and start it in host mode if one does not exist yet. This is a convenience for dev-time testing, as usually the network manager is created on the main menu before the GameController is instantiated.</remarks>
public sealed class GameController : NetworkBehaviour
{
    [Tooltip("Prefab for spawning the network manager, if it does not already exist.")]
    public MercNetworkManager networkManagerPrefab;

    [Scene, Tooltip("Scene to additively load on the client, and move their player object to, after connection and initial load of the online scene.")]
    public string firstAdditiveScene;

    /// <summary>The active network manager.</summary>
    private MercNetworkManager networkManager;

    /// <summary>All players currently connected to this server.</summary>
    public SyncPlayerList onlinePlayerList = new SyncPlayerList();

    /// <summary>On the server, a reference to the coroutine that is responsible for loading all scenes at startup (so that it can be waited for if necessary).</summary>
    private Coroutine loadAllScenesCoroutine;

    /// <summary>On the client, tracks an outstanding scene load operation that the server has not let complete yet.</summary>
    private AsyncOperation clientSceneLoadOperation;

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
        base.OnStartServer();
        NetworkServer.RegisterHandler<SceneReadyMessage>(ClientSceneReady);

        foreach (var nickname in networkManager.networkAuthenticator.nicknames.Values)
        {
            onlinePlayerList.Add(nickname);
        }

        networkManager.clientConnectedToServer.AddListener(ClientConnectedToServer);
        networkManager.clientDisconnectedFromServer.AddListener(ClientDisconnectedFromServer);
        networkManager.serverAddedPlayer.AddListener(ServerAddedPlayer);

        loadAllScenesCoroutine = StartCoroutine(LoadAllScenes());
    }

    public override void OnStartClient()
    {
        base.OnStartClient();
        NetworkClient.RegisterHandler<ActivateSceneMessage>(ActivateScene);

        networkManager.clientChangeScene.AddListener(ClientChangeScene);
    }

    void OnDestroy()
    {
        networkManager?.clientConnectedToServer.RemoveListener(ClientConnectedToServer);
        networkManager?.clientDisconnectedFromServer.RemoveListener(ClientDisconnectedFromServer);
    }

    [Server]
    private IEnumerator LoadAllScenes()
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
            yield return SceneManager.LoadSceneAsync(i, LoadSceneMode.Additive);
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

    [Server]
    private PlayerController PlayerForConnection(NetworkConnection connection)
    {
        return connection.identity.GetComponent<PlayerController>();
    }

    [Server]
    private void ClientSceneReady(NetworkConnection connection, SceneReadyMessage message)
    {
        Scene? scene = SceneManagerExtensions.GetSceneByPathOrName(message.sceneNameOrPath);
        if (scene == null)
        {
            Debug.LogWarning($"Scene {message.sceneNameOrPath} not loaded on server despite client readying it");
            return;
        }

        PlayerForConnection(connection).MoveToScene(scene.Value);
    }

    [Server]
    private void ServerAddedPlayer(NetworkConnection connection)
    {
        string scenePath = firstAdditiveScene;
        Debug.Log($"Asking player {connection} to load {scenePath}");

        // In host mode, if this is the local player, special case our activation path as the scene may already have been loaded.
        if (connection.identity.isLocalPlayer)
        {
            StartCoroutine(WaitForSceneToLoadThenMovePlayer(scenePath, connection.identity.gameObject));
        }
        else
        {
            connection.Send(new SceneMessage { sceneName = scenePath, sceneOperation = SceneOperation.LoadAdditive, customHandling = true });
        }
    }

    [Server]
    private IEnumerator WaitForSceneToLoadThenMovePlayer(string sceneNameOrPath, GameObject player)
    {
        yield return loadAllScenesCoroutine;

        // This scene should be loaded by the above.
        Scene? scene = SceneManagerExtensions.GetSceneByPathOrName(sceneNameOrPath);

        if (SceneManager.SetActiveScene(scene.Value))
        {
            SceneManager.MoveGameObjectToScene(player, scene.Value);
            Debug.Log($"Moved host player to {sceneNameOrPath}");
        }
        else
        {
            Debug.LogWarning($"Failed to change active scene to {sceneNameOrPath}");
        }
    }

    [Client]
    private void ClientChangeScene(string sceneNameOrPath, SceneOperation sceneOperation)
    {
        if (clientSceneLoadOperation != null)
        {
            Debug.LogWarning($"Scene load operation already in progress!");
        }

        switch (sceneOperation)
        {
            case SceneOperation.Normal:
                clientSceneLoadOperation = SceneManager.LoadSceneAsync(sceneNameOrPath);
                break;

            case SceneOperation.LoadAdditive:
                if (SceneManagerExtensions.GetSceneByPathOrName(sceneNameOrPath) == null)
                {
                    Debug.Log($"Starting to load scene {sceneNameOrPath}");
                    clientSceneLoadOperation = SceneManager.LoadSceneAsync(sceneNameOrPath, LoadSceneMode.Additive);
                }
                else
                {
                    Debug.Log($"Scene {sceneNameOrPath} already loaded, skipping");
                }

                break;

            case SceneOperation.UnloadAdditive:
                if (SceneManagerExtensions.GetSceneByPathOrName(sceneNameOrPath) != null)
                {
                    Debug.Log($"Starting to unload scene {sceneNameOrPath}");
                    clientSceneLoadOperation = SceneManager.UnloadSceneAsync(sceneNameOrPath, UnloadSceneOptions.UnloadAllEmbeddedSceneObjects);
                    clientSceneLoadOperation.completed += op => clientSceneLoadOperation = null;
                }
                else
                {
                    Debug.Log($"Scene {sceneNameOrPath} already unloaded, skipping");
                }

                // The rest of the logic is really only applicable to loading.
                return;
        }

        if (clientSceneLoadOperation != null)
        {
            clientSceneLoadOperation.allowSceneActivation = false;
        }

        StartCoroutine(NotifyServerWhenSceneReady(sceneNameOrPath));

    }

    [Client]
    private IEnumerator NotifyServerWhenSceneReady(string sceneNameOrPath)
    {
        if (clientSceneLoadOperation != null)
        {
            while (clientSceneLoadOperation.progress < 0.9f)
            {
                yield return null;
            }
        }

        Debug.Log($"Prepared scene {sceneNameOrPath}, notifying server");
        NetworkClient.Send(new SceneReadyMessage { sceneNameOrPath = sceneNameOrPath });
    }

    [Client]
    private void ActivateScene(NetworkConnection connection, ActivateSceneMessage message)
    {
        if (clientSceneLoadOperation == null)
        {
            Debug.LogWarning($"No in-progress scene load for {message.sceneNameOrPath}");
        }

        Debug.Log($"Activating {message.sceneNameOrPath}");
        StartCoroutine(WaitForSceneActivationThenSetActive(message.sceneNameOrPath));
    }

    [Client]
    private IEnumerator WaitForSceneActivationThenSetActive(string sceneNameOrPath)
    {
        if (clientSceneLoadOperation != null)
        {
            yield return clientSceneLoadOperation;
            clientSceneLoadOperation = null;
        }

        Scene scene = SceneManagerExtensions.GetSceneByPathOrName(sceneNameOrPath).Value;
        if (!SceneManager.SetActiveScene(scene))
        {
            Debug.LogWarning($"Failed to activate scene {sceneNameOrPath}");
        }
    }
}
