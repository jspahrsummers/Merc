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

    [SyncVar(hook = nameof(OnPositionChanged))]
    private Vector2 position;

    [SyncVar(hook = nameof(OnRotationChanged))]
    private float rotation;

    private Coroutine syncPhysicsCoroutine;

    void Start()
    {
        MercDebug.EnforceField(rigidbody);
        MercDebug.EnforceField(networkTransform);

        velocity = rigidbody.velocity;
        angularVelocity = rigidbody.angularVelocity;
        position = rigidbody.position;
        rotation = rigidbody.rotation;

        networkTransform.enabled = false;
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
        if (hasAuthority)
        {
            return;
        }

        rigidbody.velocity = newValue;
    }

    private void OnAngularVelocityChanged(float oldValue, float newValue)
    {
        if (hasAuthority)
        {
            return;
        }

        rigidbody.angularVelocity = newValue;
    }

    private void OnPositionChanged(Vector2 oldValue, Vector2 newValue)
    {
        if (hasAuthority)
        {
            return;
        }

        rigidbody.position = newValue;
    }

    private void OnRotationChanged(float oldValue, float newValue)
    {
        if (hasAuthority)
        {
            return;
        }

        rigidbody.rotation = newValue;
    }

    private IEnumerator SyncUpdatedPhysics()
    {
        // Write updates _after_ all other physics calculations
        while (true)
        {
            velocity = rigidbody.velocity;
            angularVelocity = rigidbody.angularVelocity;
            rotation = rigidbody.rotation;
            position = rigidbody.position;
            yield return new WaitForFixedUpdate();
        }
    }
}