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

    void Start()
    {
        MercDebug.EnforceField(image);
        startTime = Time.time;
        StartCoroutine(FadeOut());
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
