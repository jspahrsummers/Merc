using UnityEngine;
using Mirror;

/// <summary>Attached to any object that can be damaged (e.g., by weapons).</summary>
public sealed class DamageableController : NetworkBehaviour
{
    [Tooltip("Starting shields for this object.")]
    public float shields;

    [Tooltip("Starting hull for this object.")]
    public float hull;

    /// <summary>Afflicts this object with the specified amount of damage, destroying it if the hull drops to 0 as a result.</summary>
    [Server]
    public void ApplyDamage(Damage damage)
    {
        float shieldImpact = Mathf.Min(shields, damage.shields);
        shields -= shieldImpact;

        if (shields <= 0)
        {
            float hullImpact = Mathf.Max(damage.hull - shieldImpact, 0);
            hull -= hullImpact;
        }

        if (hull <= 0)
        {
            // TODO: Explosion
            Destroy(gameObject);
        }
    }
}
