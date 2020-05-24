using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DestructibleController : MonoBehaviour
{
    public float lifetime = Mathf.Infinity;
    public GameObject explosionPrefab;

    private float m_startTime;

    // Start is called before the first frame update
    void Start()
    {
        m_startTime = Time.time;
    }

    private void Explode()
    {
        Destroy(gameObject);
        if (explosionPrefab)
        {
            Instantiate(explosionPrefab, transform.position, transform.rotation, transform.parent);
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (Time.time - m_startTime > lifetime)
        {
            Debug.Log($"Expiring {this}");
            Explode();
        }
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        Debug.Log($"Collision with {other}");
        Explode();
    }
}
