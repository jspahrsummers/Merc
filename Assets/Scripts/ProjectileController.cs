using System.Collections;
using UnityEngine;
using Mirror;

/// <summary>Manages the lifecycle of a projectile (e.g., a fired weapon).</summary>
public sealed class ProjectileController : NetworkBehaviour
{
    [Tooltip("Number of seconds that this projectile should persist for, before disappearing.")]
    public float lifetime = Mathf.Infinity;

    [Tooltip("The rigidbody of the projectile, for applying initial physics effects.")]
    public new Rigidbody rigidbody;

    [Tooltip("The collider for the projectile, for detecting collisions and applying damage. Automatically enabled on the server.")]
    public new Collider collider;

    [Tooltip("The damage this projectile inflicts if it collides with something that can be damaged.")]
    public Damage damage;

    [Tooltip("If set, an audio clip to play when a collision occurs and the projectile is destroyed.")]
    public AudioClip collisionAudio;

    [SyncVar, Tooltip("Initial velocity to set when this object is spawned.")]
    public Vector3 initialVelocity;

    [SyncVar, Tooltip("Impulse force to apply when this object is spawned.")]
    public float firedForce;

    /// <summary>If set, the NetworkBehaviour.netId of the object which created this projectile (to be ignored in collsions).</summary>
    [HideInInspector]
    public uint creatorNetId;

    public override void OnStartServer()
    {
        StartCoroutine(DisappearAfterLifetime());

        if (collider)
        {
            collider.enabled = true;
        }
    }

    [Server]
    private IEnumerator DisappearAfterLifetime()
    {
        yield return new WaitForSeconds(lifetime);
        Destroy(gameObject);
    }

    void Start()
    {
        rigidbody.velocity = initialVelocity;
        rigidbody.AddRelativeForce(Vector3.forward * firedForce, ForceMode.Impulse);
    }

    void OnTriggerEnter(Collider other)
    {
        if (!damage)
        {
            return;
        }

        var damageable = other.GetComponent<DamageableController>();
        if (damageable == null || damageable.netId == creatorNetId)
        {
            return;
        }

        if (collisionAudio)
        {
            AudioSource.PlayClipAtPoint(collisionAudio, rigidbody.position);
        }

        damageable.ApplyDamage(damage);
        Destroy(gameObject);
    }
}
