using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class HyperspaceArrivalController : MonoBehaviour
{
    public float fadeSpeed;

    [HideInInspector]
    public float arrivalAngle;

    private float m_startTime;

    private Image image => GetComponentInChildren<Image>();
    private GameObject player => GameObject.FindWithTag("Player");

    void Start()
    {
        SceneManager.activeSceneChanged += OnChangedActiveScene;
    }

    private void OnChangedActiveScene(Scene current, Scene next)
    {
        m_startTime = Time.time;
        player.GetComponent<PlayerShipController>().OnArrivalFromHyperspaceJump(arrivalAngle);
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
