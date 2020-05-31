using System.Collections;
using UnityEngine;

public sealed class ProjectileController : MonoBehaviour
{
    public ProjectileScriptableObject projectile;
    public GameObject explosionPrefab;
    public new Rigidbody2D rigidbody => GetComponent<Rigidbody2D>();

    void Start()
    {
        if (rigidbody)
        {
            rigidbody.mass = projectile.mass;
        }

        if (projectile.lifetime != Mathf.Infinity)
        {
            StartCoroutine(ExplodeAfterLifetime());
        }
    }

    private IEnumerator ExplodeAfterLifetime()
    {
        yield return new WaitForSeconds(projectile.lifetime);
        Explode();
    }

    private void Explode()
    {
        Destroy(gameObject);
        if (explosionPrefab)
        {
            Instantiate(explosionPrefab, transform.position, transform.rotation, transform.parent);
        }

        // TODO: Damage objects nearby
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        Debug.Log($"Collision between {this} and {other}");
        Explode();
    }
}
