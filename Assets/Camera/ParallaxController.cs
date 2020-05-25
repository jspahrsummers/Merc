using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParallaxController : MonoBehaviour
{
    private const float BACKGROUND_INCREMENTAL_EXPANSION = 25;

    private static Dictionary<(int x, int y), ParallaxController> allControllers = new Dictionary<(int x, int y), ParallaxController>();
    private (int x, int y) m_gridTag;

    private SpriteRenderer backgroundRenderer => GetComponent<SpriteRenderer>();

    private ParallaxController GetControllerAtOffset(int xOffset, int yOffset, bool instantiate = false)
    {
        var lookupTag = (x: m_gridTag.x + xOffset, y: m_gridTag.y + yOffset);
        if (allControllers.ContainsKey(lookupTag))
        {
            return allControllers[lookupTag];
        }
        else
        {
            return null;
        }
    }

    private ParallaxController left => GetControllerAtOffset(-1, 0);
    private ParallaxController right => GetControllerAtOffset(1, 0);
    private ParallaxController top => GetControllerAtOffset(0, 1);
    private ParallaxController bottom => GetControllerAtOffset(0, -1);

    private void InstantiateControllerAtOffset(int xOffset, int yOffset)
    {
        var newTag = (x: m_gridTag.x + xOffset, y: m_gridTag.y + yOffset);

        var newPosition = transform.position;
        newPosition.x += backgroundRenderer.sprite.bounds.size.x * xOffset;
        newPosition.y += backgroundRenderer.sprite.bounds.size.y * yOffset;

        var controller = Instantiate<ParallaxController>(this, newPosition, transform.rotation, transform.parent);
        controller.m_gridTag = newTag;

        Debug.Assert(!allControllers.ContainsKey(newTag));
        allControllers[newTag] = controller;
    }

    void OnBecomeInvisible()
    {
        Destroy(gameObject);
    }

    void OnDestroy()
    {
        allControllers.Remove(m_gridTag);
    }

    void Start()
    {
        if (!allControllers.ContainsKey(m_gridTag))
        {
            allControllers[m_gridTag] = this;
        }
    }

    void Update()
    {
        var minPoint = Camera.main.WorldToScreenPoint(backgroundRenderer.bounds.min);
        var maxPoint = Camera.main.WorldToScreenPoint(backgroundRenderer.bounds.max);

        if (minPoint.x >= 0 && !left)
        {
            InstantiateControllerAtOffset(-1, 0);
        }

        if (maxPoint.x <= Screen.width && !right)
        {
            InstantiateControllerAtOffset(1, 0);
        }

        if (minPoint.y >= 0 && !bottom)
        {
            InstantiateControllerAtOffset(0, -1);
        }

        if (maxPoint.y <= Screen.height && !top)
        {
            InstantiateControllerAtOffset(0, 1);
        }
    }
}
