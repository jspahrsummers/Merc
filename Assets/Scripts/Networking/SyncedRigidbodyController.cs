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

    void OnEnable()
    {
        StartCoroutine(SyncUpdatedPhysics());
    }

    void OnDisable()
    {
        StopAllCoroutines();
    }

    void FixedUpdate()
    {
        // Sync from server _before_ other physics calculations
        if (!hasAuthority)
        {
            syncedPhysics.ApplyToRigidbody(rigidbody);
        }
    }

    IEnumerator SyncUpdatedPhysics()
    {
        // Sync to server _after_ other physics calculations
        while (hasAuthority)
        {
            yield return new WaitForFixedUpdate();
            syncedPhysics = new SyncedPhysics(rigidbody);
        }
    }
}