using System.Collections;
using UnityEngine;
using Mirror;

public sealed class ProjectileController : NetworkBehaviour // TODO: IDamageable
{
    public ProjectileScriptableObject projectile;
    // TODO: Destructible
    public ExplodableController explodable;
    public new Rigidbody2D rigidbody;
    public new Collider2D collider;

    [SyncVar]
    public uint spawnerNetId;

    [SyncVar]
    public Vector2 initialForce;

    public override void OnStartClient()
    {
        if (this.IsServerOrHasAuthority())
        {
            return;
        }

        rigidbody.bodyType = RigidbodyType2D.Kinematic;
    }

    void Start()
    {
        MercDebug.EnforceField(projectile);
        MercDebug.EnforceField(explodable);

        if (rigidbody)
        {
            rigidbody.mass = projectile.mass;
            rigidbody.AddRelativeForce(initialForce, ForceMode2D.Impulse);
        }

        if (projectile.lifetime != Mathf.Infinity)
        {
            StartCoroutine(ExplodeAfterLifetime());
        }

        NetworkIdentity spawner;
        if (NetworkIdentity.spawned.TryGetValue(spawnerNetId, out spawner))
        {
            var spawnerCollider = spawner.GetComponent<Collider2D>();
            if (spawnerCollider != null)
            {
                Physics2D.IgnoreCollision(collider, spawnerCollider);
            }
        }
    }

    private IEnumerator ExplodeAfterLifetime()
    {
        yield return new WaitForSeconds(projectile.lifetime);
        explodable.Explode();
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        if (!isServer)
        {
            return;
        }

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
