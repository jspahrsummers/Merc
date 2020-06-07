using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(SpriteRenderer))]
public sealed class ParallaxController : MonoBehaviour
{
    public ParallaxController prefab;

    private static Dictionary<(int x, int y), ParallaxController> allControllers = new Dictionary<(int x, int y), ParallaxController>();
    private (int x, int y) gridTag;

    private SpriteRenderer backgroundRenderer => GetComponent<SpriteRenderer>();

    private ParallaxController GetControllerAtOffset(int xOffset, int yOffset, bool instantiate = false)
    {
        var lookupTag = (x: gridTag.x + xOffset, y: gridTag.y + yOffset);
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
        var newTag = (x: gridTag.x + xOffset, y: gridTag.y + yOffset);

        Vector3 newPosition = transform.position;
        newPosition.x += backgroundRenderer.sprite.bounds.size.x * xOffset;
        newPosition.y += backgroundRenderer.sprite.bounds.size.y * yOffset;

        var controller = Instantiate<ParallaxController>(prefab, newPosition, transform.rotation, transform.parent);
        controller.gridTag = newTag;

        Debug.Assert(!allControllers.ContainsKey(newTag));
        allControllers[newTag] = controller;
    }

    void OnBecomeInvisible()
    {
        Destroy(gameObject);
    }

    void OnDestroy()
    {
        allControllers.Remove(gridTag);
    }

    void Start()
    {
        if (!allControllers.ContainsKey(gridTag))
        {
            allControllers[gridTag] = this;
        }
    }

    void Update()
    {
        Vector3 minPoint = Camera.main.WorldToScreenPoint(backgroundRenderer.bounds.min);
        Vector3 maxPoint = Camera.main.WorldToScreenPoint(backgroundRenderer.bounds.max);

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
