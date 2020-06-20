using System.Collections;
using UnityEngine;
using Mirror;

// This class assumes that the transform is synced with a NetworkTransform.
[RequireComponent(typeof(NetworkIdentity))]
public sealed class SyncedRigidbodyController : NetworkBehaviour
{
    public new Rigidbody2D rigidbody;

    [SyncVar]
    private SyncedPhysics syncedPhysics;

    private Coroutine syncPhysicsCoroutine;

    void Start()
    {
        syncedPhysics = new SyncedPhysics(rigidbody);
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

    void FixedUpdate()
    {
        syncedPhysics.ApplyToRigidbody(rigidbody);
    }

    IEnumerator SyncUpdatedPhysics()
    {
        // Write updates _after_ all other physics calculations
        while (true)
        {
            syncedPhysics = new SyncedPhysics(rigidbody);
            yield return new WaitForFixedUpdate();
        }
    }
}