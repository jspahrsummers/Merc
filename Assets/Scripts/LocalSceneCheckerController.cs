using UnityEngine;
using UnityEngine.SceneManagement;

/// <summary>Used on <b>local only</b> objects to prevent them being shown when their scene is not active.</summary>
/// <remarks>For client only operation, this is not really necessary; but when the client is also functioning as a server (i.e., "host mode," with all scenes loaded), this prevents the player from seeing objects they shouldn't.</remarks>
public sealed class LocalSceneCheckerController : MonoBehaviour
{
    void Awake()
    {
        SceneManager.activeSceneChanged += ChangedActiveScene;
    }

    void OnEnable()
    {
        ChangedActiveScene(gameObject.scene, SceneManager.GetActiveScene());
    }

    void OnDestroy()
    {
        SceneManager.activeSceneChanged -= ChangedActiveScene;
    }

    private void ChangedActiveScene(Scene previous, Scene next)
    {
        gameObject.SetActive(gameObject.scene == next);
    }
}
