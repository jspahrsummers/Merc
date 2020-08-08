using UnityEngine;
using Mirror;

/// <summary>Attached to any object that can be damaged (e.g., by weapons).</summary>
public sealed class DamageableController : NetworkBehaviour
{
    [Tooltip("Starting shields for this object.")]
    public float shields;

    [Tooltip("Starting hull for this object.")]
    public float hull;

    [Tooltip("The primary renderer for the object, which will be disabled if it is destroyed but we want to play an animation.")]
    public new Renderer renderer;

    [Tooltip("If set, an explosion particle system to start when the object is destroyed.")]
    public ParticleSystem explosion;

    [Tooltip("If set, an audio clip to play when the object is destroyed.")]
    public AudioClip explosionAudio;

    /// <summary>Set to true when destruction animations, etc. have already begun, so that we do not perform them multiple times.</summary>
    private bool destroyed = false;

    /// <summary>When animating destruction, the number of additional seconds to wait for all clients to destroy this object before authoritatively destroying it on the server.</summary>
    const float DestroyToleranceForClientLatency = 1;

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
            Explode();
        }
    }

    [Server]
    private void Explode()
    {
        if (destroyed)
        {
            return;
        }

        destroyed = true;

        float destroyDelay = 0;
        if (explosion)
        {
            Debug.Log($"Telling clients to explode {gameObject}");
            RpcExplode();
            destroyDelay = explosion.main.duration + DestroyToleranceForClientLatency;
        }

        Destroy(gameObject, destroyDelay);
    }

    [ClientRpc]
    private void RpcExplode()
    {
        Debug.Log($"Animating explosion of {gameObject}");

        if (explosionAudio)
        {
            AudioSource.PlayClipAtPoint(explosionAudio, explosion?.transform.position ?? transform.position);
        }

        if (renderer)
        {
            renderer.enabled = false;
        }

        if (explosion)
        {
            explosion.Play();
        }
    }
}
