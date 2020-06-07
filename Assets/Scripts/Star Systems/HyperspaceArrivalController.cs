using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public sealed class HyperspaceArrivalController : MonoBehaviour
{
    public Image image;
    public float fadeSpeed;

    [HideInInspector]
    public HyperspaceJump hyperspaceJump;

    private float startTime;

    void Awake()
    {
        MercDebug.Invariant(image != null, "Hyperspace fade image should not be null");
    }

    void OnEnable()
    {
        SceneManager.activeSceneChanged += OnChangedActiveScene;
    }

    void OnDisable()
    {
        SceneManager.activeSceneChanged -= OnChangedActiveScene;
    }

    private void OnChangedActiveScene(Scene current, Scene next)
    {
        startTime = Time.time;
        StartCoroutine(FadeOut());

        var gameController = FindObjectOfType<GameController>();
        MercDebug.Invariant(gameController != null, "Could not locate GameController after scene change");
        gameController.OnCompletedHyperspaceJump(hyperspaceJump);
    }

    private IEnumerator FadeOut()
    {
        while (image.color.a > 0)
        {
            Color color = image.color;
            color.a -= fadeSpeed * Time.deltaTime;
            image.color = color;
            yield return null;
        }

        Destroy(gameObject);
    }
}
