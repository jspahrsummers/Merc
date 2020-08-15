using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.SceneManagement;
using Mirror;
using MercExtensions;

/// <summary>Custom NetworkManager type that supports listeners for the default "callbacks."</summary>
public sealed class MercNetworkManager : NetworkManager
{
    [Scene, Tooltip("Scene to additively load on the client, and move their player object to, after connection and initial load of the online scene.")]
    public string firstAdditiveScene;

    [Tooltip("The authenticator to use for connections via this network manager.")]
    public MercNetworkAuthenticator networkAuthenticator;

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

    /// <summary>Sent from the client to the server when a scene has been loaded, but not yet activated, to allow the server to issue the next instruction.</summary>
    private sealed class SceneReadyMessage : MessageBase
    {
        /// <summary>The scene that was loaded.</summary>
        public string sceneNameOrPath;
    }

    /// <summary>Sent from the server to the client, instructing it to activate a specific scene. The scene must have been loaded, but not already activated.</summary>
    private sealed class ActivateSceneMessage : MessageBase
    {
        /// <summary>The scene to activate.</summary>
        public string sceneNameOrPath;
    }

    /// <summary>On the client, tracks all outstanding scene load operations that the server has not let complete yet (keyed by sceneNameOrPath).</summary>
    private Dictionary<string, AsyncOperation> sceneLoadOperations = new Dictionary<string, AsyncOperation>();

    public static MercNetworkManager Find()
    {
        return (MercNetworkManager)NetworkManager.singleton;
    }

    public override void OnStartServer()
    {
        base.OnStartServer();
        NetworkServer.RegisterHandler<SceneReadyMessage>(ClientSceneReady);
    }

    public override void OnStartClient()
    {
        base.OnStartClient();
        NetworkClient.RegisterHandler<ActivateSceneMessage>(ActivateScene);
    }

    private void ClientSceneReady(NetworkConnection connection, SceneReadyMessage message)
    {
        Scene? scene = SceneManagerExtensions.GetSceneByPathOrName(message.sceneNameOrPath);
        if (scene == null)
        {
            Debug.LogWarning($"Scene {message.sceneNameOrPath} not loaded on server despite client readying it");
            return;
        }

        Debug.Log($"Moving {connection} to scene {message.sceneNameOrPath}");
        SceneManager.MoveGameObjectToScene(connection.identity.gameObject, scene.Value);
        connection.Send(new ActivateSceneMessage { sceneNameOrPath = message.sceneNameOrPath });
    }

    private void ActivateScene(NetworkConnection connection, ActivateSceneMessage message)
    {
        AsyncOperation operation;
        if (sceneLoadOperations.TryGetValue(message.sceneNameOrPath, out operation))
        {
            operation.allowSceneActivation = true;
        }
        else
        {
            Debug.LogWarning($"No in-progress scene load for {message.sceneNameOrPath}");
        }

        Debug.Log($"Activating {message.sceneNameOrPath}");
        StartCoroutine(WaitForSceneActivationThenSetActive(operation, message.sceneNameOrPath));
    }

    private IEnumerator WaitForSceneActivationThenSetActive(AsyncOperation operation, string sceneNameOrPath)
    {
        if (operation != null)
        {
            yield return operation;
        }

        Scene scene = SceneManagerExtensions.GetSceneByPathOrName(sceneNameOrPath).Value;
        if (!SceneManager.SetActiveScene(scene))
        {
            Debug.LogWarning($"Failed to activate scene {sceneNameOrPath}");
        }
    }

    // Invoked on the client after authenticating successfully to the server.
    public override void OnClientConnect(NetworkConnection connection)
    {
        base.OnClientConnect(connection);
        clientConnected.Invoke();
    }

    public override void OnClientChangeScene(string sceneNameOrPath, SceneOperation sceneOperation, bool customHandling)
    {
        if (!customHandling)
        {
            base.OnClientChangeScene(sceneNameOrPath, sceneOperation, customHandling);
            return;
        }

        if (sceneLoadOperations.ContainsKey(sceneNameOrPath))
        {
            Debug.LogWarning($"Scene change operation for {sceneNameOrPath} already in progress, skipping");
            return;
        }

        AsyncOperation asyncOperation = null;

        switch (sceneOperation)
        {
            case SceneOperation.Normal:
                asyncOperation = SceneManager.LoadSceneAsync(sceneNameOrPath);
                break;

            case SceneOperation.LoadAdditive:
                if (SceneManagerExtensions.GetSceneByPathOrName(sceneNameOrPath) == null)
                {
                    Debug.Log($"Starting to load scene {sceneNameOrPath}");
                    asyncOperation = SceneManager.LoadSceneAsync(sceneNameOrPath, LoadSceneMode.Additive);
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
                    asyncOperation = SceneManager.UnloadSceneAsync(sceneNameOrPath, UnloadSceneOptions.UnloadAllEmbeddedSceneObjects);
                }
                else
                {
                    Debug.Log($"Scene {sceneNameOrPath} already unloaded, skipping");
                }

                break;
        }

        if (asyncOperation != null)
        {
            asyncOperation.allowSceneActivation = false;
            sceneLoadOperations[sceneNameOrPath] = asyncOperation;
            asyncOperation.completed += op => sceneLoadOperations.Remove(sceneNameOrPath);
        }

        if (sceneOperation != SceneOperation.UnloadAdditive)
        {
            StartCoroutine(NotifyServerWhenSceneReady(sceneNameOrPath, asyncOperation));
        }
    }

    private IEnumerator NotifyServerWhenSceneReady(string sceneNameOrPath, AsyncOperation operation)
    {
        if (operation != null)
        {
            while (operation.progress < 0.9f)
            {
                yield return null;
            }
        }

        Debug.Log($"Prepared scene {sceneNameOrPath}, notifying server");
        NetworkClient.Send(new SceneReadyMessage { sceneNameOrPath = sceneNameOrPath });
    }

    public override void OnClientError(NetworkConnection connection, int errorCode)
    {
        base.OnClientError(connection, errorCode);
        clientError.Invoke();
    }

    public override void OnServerConnect(NetworkConnection connection)
    {
        base.OnServerConnect(connection);
        clientConnectedToServer.Invoke(connection);
    }

    public override void OnServerAddPlayer(NetworkConnection connection)
    {
        base.OnServerAddPlayer(connection);

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

    private IEnumerator WaitForSceneToLoadThenMovePlayer(string sceneNameOrPath, GameObject player)
    {
        // This scene should be loaded by GameController already.
        Scene? scene;
        do
        {
            yield return null;
            scene = SceneManagerExtensions.GetSceneByPathOrName(sceneNameOrPath);
        } while (scene == null || !scene.Value.isLoaded);

        SceneManager.SetActiveScene(scene.Value);
        SceneManager.MoveGameObjectToScene(player, scene.Value);
        Debug.Log($"Moved host player to {sceneNameOrPath}");
    }

    public override void OnServerError(NetworkConnection connection, int errorCode)
    {
        base.OnServerError(connection, errorCode);
        serverError.Invoke();
    }

    public override void OnServerDisconnect(NetworkConnection connection)
    {
        base.OnServerDisconnect(connection);
        clientDisconnectedFromServer.Invoke(connection);
    }
}
