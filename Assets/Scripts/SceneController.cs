using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using Mirror;

public sealed class SceneController : NetworkBehaviour
{
    private Dictionary<Scene, StarSystemController> starSystemControllers = new Dictionary<Scene, StarSystemController>();

    public static SceneController Find()
    {
        return GameObject.FindWithTag("SceneController")?.GetComponent<SceneController>();
    }

    [Server]
    private void LoadAllScenes()
    {
        Scene activeScene = SceneManager.GetActiveScene();
        var count = SceneManager.sceneCountInBuildSettings;

        // Skip game base scene at build index 0
        for (int i = 1; i < count; i++)
        {
            if (i == activeScene.buildIndex)
            {
                continue;
            }

            SceneManager.LoadSceneAsync(i, LoadSceneMode.Additive);
        }
    }

    public override void OnStartServer()
    {
        if (!isClient)
        {
            LoadAllScenes();
        }
    }

    public void AddStarSystemController(StarSystemController controller)
    {
        starSystemControllers.Add(controller.gameObject.scene, controller);
    }

    public void RemoveStarSystemController(StarSystemController controller)
    {
        Scene scene = controller.gameObject.scene;
        MercDebug.Invariant(starSystemControllers.ContainsKey(scene), $"Controller {controller} was not registered to scene {scene}");
        starSystemControllers.Remove(scene);
    }

    public StarSystemController StarSystemForObject(GameObject gameObject)
    {
        return starSystemControllers[gameObject.scene];
    }
}
