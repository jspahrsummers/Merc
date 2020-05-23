using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DestructibleController : MonoBehaviour
{
    public float lifetime = Mathf.Infinity;

    private float m_startTime;

    // Start is called before the first frame update
    void Start()
    {
        m_startTime = Time.time;
    }

    // Update is called once per frame
    void Update()
    {
        if (Time.time - m_startTime > lifetime)
        {
            Debug.Log($"Expiring {this}");
            Destroy(gameObject);
        }
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        Debug.Log($"Collision with {other}");
        Destroy(gameObject);
    }
}
