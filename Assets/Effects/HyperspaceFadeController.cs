using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class HyperspaceFadeController : MonoBehaviour
{
    public float fadeSpeed;

    private float m_startTime;

    private Image image => GetComponent<Image>();

    void Start()
    {
        m_startTime = Time.time;
    }

    void Update()
    {
        var color = image.color;
        color.a -= fadeSpeed * Time.deltaTime;
        image.color = color;

        if (color.a <= 0)
        {
            Destroy(gameObject);
        }
    }
}
