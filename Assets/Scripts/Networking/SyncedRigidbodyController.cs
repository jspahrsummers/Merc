using System.Collections;
using UnityEngine;
using Mirror;

public sealed class SyncedRigidbodyController : NetworkBehaviour
{
    public new Rigidbody2D rigidbody;
    public NetworkTransform networkTransform;

    [SyncVar(hook = nameof(OnVelocityChanged))]
    private Vector2 velocity;

    [SyncVar(hook = nameof(OnAngularVelocityChanged))]
    private float angularVelocity;

    private Coroutine syncPhysicsCoroutine;

    void Start()
    {
        MercDebug.EnforceField(rigidbody);
        MercDebug.EnforceField(networkTransform);

        velocity = rigidbody.velocity;
        angularVelocity = rigidbody.angularVelocity;
    }

    void OnEnable()
    {
        syncPhysicsCoroutine = StartCoroutine(SyncUpdatedPhysics());
    }

    void OnDisable()
    {
        if (syncPhysicsCoroutine != null)
        {
            StopCoroutine(syncPhysicsCoroutine);
            syncPhysicsCoroutine = null;
        }
    }

    private void OnVelocityChanged(Vector2 oldValue, Vector2 newValue)
    {
        rigidbody.velocity = newValue;
    }

    private void OnAngularVelocityChanged(float oldValue, float newValue)
    {
        rigidbody.angularVelocity = newValue;
    }

    IEnumerator SyncUpdatedPhysics()
    {
        // Write updates _after_ all other physics calculations
        while (true)
        {
            velocity = rigidbody.velocity;
            angularVelocity = rigidbody.angularVelocity;
            yield return new WaitForFixedUpdate();
        }
    }
}