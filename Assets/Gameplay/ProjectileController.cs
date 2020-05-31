using System.Collections;
using UnityEngine;

public sealed class ProjectileController : MonoBehaviour // TODO: IDamageable
{
    public ProjectileScriptableObject projectile;
    // TODO: Destructible
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

        // TODO: Damage objects nearby (Collider2.Cast?)
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        Debug.Log($"Collision between {this} and {other}");
        Explode();

        var damageable = other.gameObject.GetComponent<IDamageable>();
        if (damageable != null)
        {
            Debug.Log($"Damaging other object {damageable}");
            damageable.ApplyDamage(projectile.groundZeroDamage);
        }
    }
}
