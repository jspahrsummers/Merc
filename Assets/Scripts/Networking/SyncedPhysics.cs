using UnityEngine;

public readonly struct SyncedPhysics
{
    public readonly Vector2 velocity;
    public readonly float angularVelocity;

    public SyncedPhysics(Rigidbody2D rigidbody)
    {
        this.velocity = rigidbody.velocity;
        this.angularVelocity = rigidbody.angularVelocity;
    }

    public void ApplyToRigidbody(Rigidbody2D rigidbody)
    {
        rigidbody.velocity = this.velocity;
        rigidbody.angularVelocity = this.angularVelocity;
    }
}