using System.Collections;
using UnityEngine;
using Mirror;

/// <summary>Manages the lifecycle of a projectile (e.g., a fired weapon).</summary>
public sealed class ProjectileController : NetworkBehaviour
{
    [Tooltip("Number of seconds that this projectile should persist for, before disappearing.")]
    public float lifetime = Mathf.Infinity;

    public override void OnStartServer()
    {
        StartCoroutine(DisappearAfterLifetime());
    }

    [Server]
    private IEnumerator DisappearAfterLifetime()
    {
        yield return new WaitForSeconds(lifetime);
        Destroy(gameObject);
    }
}
