using UnityEngine;

public sealed class DestructibleController : MonoBehaviour
{
    public float lifetime = Mathf.Infinity;
    public GameObject explosionPrefab;

    private float startTime;

    void Start()
    {
        startTime = Time.time;
    }

    private void Explode()
    {
        Destroy(gameObject);
        if (explosionPrefab)
        {
            Instantiate(explosionPrefab, transform.position, transform.rotation, transform.parent);
        }
    }

    void Update()
    {
        if (Time.time - startTime > lifetime)
        {
            Explode();
        }
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        Debug.Log($"Collision between {this} and {other}");
        Explode();
    }
}
