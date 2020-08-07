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

    [SyncVar, Tooltip("Initial velocity to set when this object is spawned.")]
    public Vector3 initialVelocity;

    [SyncVar, Tooltip("Impulse force to apply when this object is spawned.")]
    public float firedForce;

    public override void OnStartServer()
    {
        StartCoroutine(DisappearAfterLifetime());
    }

    void Start()
    {
        rigidbody.velocity = initialVelocity;
        rigidbody.AddRelativeForce(Vector3.forward * firedForce, ForceMode.Impulse);
    }

    [Server]
    private IEnumerator DisappearAfterLifetime()
    {
        yield return new WaitForSeconds(lifetime);
        Destroy(gameObject);
    }
}
