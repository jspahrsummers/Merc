using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public sealed class HyperspaceArrivalController : MonoBehaviour
{
    public float fadeSpeed;

    [HideInInspector]
    public float arrivalAngle;

    private float startTime;

    // TODO: Can this component be merged?
    private Image image => GetComponentInChildren<Image>();
    private GameObject player => GameObject.FindWithTag("Player");

    void Awake()
    {
        MercDebug.Invariant(player != null, "Could not locate player object");
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

        player.GetComponent<PlayerShipController>().OnArrivalFromHyperspaceJump(arrivalAngle);
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
