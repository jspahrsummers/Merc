using System.Collections;
using UnityEngine;
using UnityEngine.UI;

/// <summary>Performs a screen-wide animated effect for the arrival of the player's ship from hyperspace.</summary>
public sealed class HyperspaceArrivalController : MonoBehaviour
{
    [Tooltip("The image which renders the hyperspace arrival effect.")]
    public Image image;

    /// <summary>How fast to fade the image's alpha (between 0 and 1) per second.</summary>
    const float FadeRate = 0.5f;

    void Start()
    {
        StartCoroutine(Fade());
    }

    private IEnumerator Fade()
    {
        while (image.color.a > 0)
        {
            Color c = image.color;
            c.a -= FadeRate * Time.deltaTime;
            image.color = c;
            yield return new WaitForEndOfFrame();
        }

        Destroy(gameObject);
    }
}
