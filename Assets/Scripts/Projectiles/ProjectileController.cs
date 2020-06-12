using System.Collections;
using UnityEngine;

public sealed class ProjectileController : MonoBehaviour // TODO: IDamageable
{
    public ProjectileScriptableObject projectile;

    // TODO: Destructible
    public ExplodableController explodable;
    public new Rigidbody2D rigidbody;

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
        explodable.Explode();
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        Debug.Log($"Collision between {this} and {other}");
        explodable.Explode();

        var damageable = other.gameObject.GetComponent<IDamageable>();
        if (damageable != null)
        {
            Debug.Log($"Damaging other object {damageable}");
            damageable.ApplyDamage(projectile.groundZeroDamage);
        }
    }
}
