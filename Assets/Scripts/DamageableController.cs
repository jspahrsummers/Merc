using UnityEngine;
using UnityEngine.Events;
using Mirror;

/// <summary>Attached to any object that can be damaged (e.g., by weapons).</summary>
public sealed class DamageableController : NetworkBehaviour
{
    [Tooltip("Starting shields for this object.")]
    public float maxShields;

    [Tooltip("Starting hull for this object.")]
    public float maxHull;

    [Tooltip("If set, an explosion particle system to start when the object is destroyed.")]
    public ParticleSystem explosion;

    [Tooltip("If set, an audio clip to play when the object is destroyed.")]
    public AudioClip explosionAudio;

    [SyncVar, Tooltip("Current shields for this object (reset at creation time).")]
    public float shields = 0;

    [SyncVar, Tooltip("Current hull for this object (reset at creation time).")]
    public float hull = 0;

    [System.Serializable]
    public sealed class DestroyedEvent : UnityEvent<DamageableController>
    {
    }

    /// <summary>An event invoked when this object is destroyed from being damaged.</summary>
    public DestroyedEvent destroyed = new DestroyedEvent();

    /// <summary>Set to true when destruction animations, etc. have already begun, so that we do not perform them multiple times.</summary>
    private bool startedDestroying = false;

    public override void OnStartServer()
    {
        base.OnStartServer();

        shields = Mathf.Max(shields, maxShields);
        hull = Mathf.Max(hull, maxHull);
    }

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

    void OnDestroy()
    {
        destroyed.Invoke(this);
    }

    [Server]
    private void Explode()
    {
        if (startedDestroying)
        {
            return;
        }

        startedDestroying = true;

        float destroyDelay = 0;
        if (explosion)
        {
            Debug.Log($"Telling clients to explode {gameObject}");
            RpcExplode();
            destroyDelay = explosion.main.duration;
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

        if (explosion)
        {
            explosion.gameObject.transform.SetParent(transform.parent);
            explosion.Play();
        }

        gameObject.SetActive(false);
    }
}
