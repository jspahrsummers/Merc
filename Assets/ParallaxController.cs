using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParallaxController : MonoBehaviour
{
    public SpriteRenderer backgroundRenderer;

    private const float BACKGROUND_INCREMENTAL_EXPANSION = 25;

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        var minPoint = Camera.main.WorldToScreenPoint(backgroundRenderer.bounds.min);
        var maxPoint = Camera.main.WorldToScreenPoint(backgroundRenderer.bounds.max);

        if (minPoint.x >= 0 || maxPoint.x <= Screen.width)
        {
            Debug.Log("Found horizontal edge of background!");
            backgroundRenderer.size += new Vector2(BACKGROUND_INCREMENTAL_EXPANSION, 0);
        }

        if (minPoint.y >= 0 || maxPoint.y <= Screen.height)
        {
            Debug.Log("Found vertical edge of background!");
            backgroundRenderer.size += new Vector2(0, BACKGROUND_INCREMENTAL_EXPANSION);
        }
    }
}
