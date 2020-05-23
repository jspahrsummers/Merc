using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParallaxController : MonoBehaviour
{
    private const float BACKGROUND_INCREMENTAL_EXPANSION = 25;

    private ParallaxController m_left;
    private ParallaxController m_right;
    private ParallaxController m_top;
    private ParallaxController m_bottom;

    private SpriteRenderer backgroundRenderer => GetComponent<SpriteRenderer>();

    void OnBecomeInvisible()
    {
        Destroy(gameObject);
    }

    void OnDestroy()
    {
        if (m_left)
        {
            m_left.m_right = null;
        }

        if (m_right)
        {
            m_right.m_left = null;
        }

        if (m_top)
        {
            m_top.m_bottom = null;
        }

        if (m_bottom)
        {
            m_bottom.m_top = null;
        }
    }

    // Start is called before the first frame update
    void Start()
    {
    }

    // Update is called once per frame
    void Update()
    {
        var minPoint = Camera.main.WorldToScreenPoint(backgroundRenderer.bounds.min);
        var maxPoint = Camera.main.WorldToScreenPoint(backgroundRenderer.bounds.max);

        if (minPoint.x >= 0 && !m_left)
        {
            Debug.Log("Found left edge of background!");

            var newPosition = transform.position;
            newPosition.x -= backgroundRenderer.sprite.bounds.size.x;
            m_left = Instantiate<ParallaxController>(this, newPosition, transform.rotation, transform.parent);
            m_left.m_right = this;

            if (m_top)
            {
                m_left.m_top = m_top.m_left;
            }

            if (m_bottom)
            {
                m_left.m_bottom = m_bottom.m_left;
            }
        }

        if (maxPoint.x <= Screen.width && !m_right)
        {
            Debug.Log("Found right edge of background!");

            var newPosition = transform.position;
            newPosition.x += backgroundRenderer.sprite.bounds.size.x;
            m_right = Instantiate<ParallaxController>(this, newPosition, transform.rotation, transform.parent);
            m_right.m_left = this;

            if (m_top)
            {
                m_right.m_top = m_top.m_right;
            }

            if (m_bottom)
            {
                m_right.m_bottom = m_bottom.m_right;
            }
        }

        if (minPoint.y >= 0 && !m_bottom)
        {
            Debug.Log("Found bottom edge of background!");

            var newPosition = transform.position;
            newPosition.y -= backgroundRenderer.sprite.bounds.size.y;
            m_bottom = Instantiate<ParallaxController>(this, newPosition, transform.rotation, transform.parent);
            m_bottom.m_top = this;

            if (m_left)
            {
                m_bottom.m_left = m_left.m_bottom;
            }

            if (m_right)
            {
                m_bottom.m_right = m_right.m_bottom;
            }
        }

        if (maxPoint.y <= Screen.height && !m_top)
        {
            Debug.Log("Found top edge of background!");

            var newPosition = transform.position;
            newPosition.y += backgroundRenderer.sprite.bounds.size.y;
            m_top = Instantiate<ParallaxController>(this, newPosition, transform.rotation, transform.parent);
            m_top.m_bottom = this;

            if (m_left)
            {
                m_top.m_left = m_left.m_top;
            }

            if (m_right)
            {
                m_top.m_right = m_right.m_top;
            }
        }
    }
}
