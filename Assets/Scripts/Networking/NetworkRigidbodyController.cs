using System.Collections;
using UnityEngine;
using Mirror;

public sealed class NetworkRigidbodyController : NetworkBehaviour
{
    public new Rigidbody2D rigidbody;
    public float localPositionSensitivity = 1f;
    public float localRotationSensitivity = 0.01f;
    public float localVelocitySensitivity = 1f;
    public float localAngularVelocitySensitivity = 0.01f;

    public struct PhysicsUpdate
    {
        public double networkTime;
        public Vector2 position;
        public float rotation;
        public Vector2 velocity;
        public float angularVelocity;

        public PhysicsUpdate(double networkTime, Rigidbody2D rigidbody)
        {
            this.networkTime = networkTime;
            this.position = rigidbody.position;
            this.rotation = rigidbody.rotation;
            this.velocity = rigidbody.velocity;
            this.angularVelocity = rigidbody.angularVelocity;
        }

        public override string ToString()
        {
            return $"PhysicsUpdate(position = {position}, rotation = {rotation}, velocity = {velocity}, angularVelocity = {angularVelocity})";
        }

        public PhysicsUpdate Scale(double factor)
        {
            return new PhysicsUpdate { networkTime = networkTime, position = position + velocity * (float)factor, rotation = (float)(rotation + angularVelocity * factor), velocity = velocity, angularVelocity = angularVelocity };
        }
    }

    void Start()
    {
        MercDebug.EnforceField(rigidbody);

        if (this.IsServerOrHasAuthority())
        {
            StartCoroutine(SubscribeToPhysics());
        }
    }

    public override void OnStartClient()
    {
        if (!this.IsServerOrHasAuthority())
        {
            rigidbody.bodyType = RigidbodyType2D.Kinematic;
            rigidbody.interpolation = RigidbodyInterpolation2D.Extrapolate;
        }
    }

    private bool Approximately(PhysicsUpdate a, PhysicsUpdate b)
    {
        return Vector2.Distance(a.position, b.position) < localPositionSensitivity
            && Mathf.DeltaAngle(a.rotation, b.rotation) < localRotationSensitivity
            && Vector2.Distance(a.velocity, b.velocity) < localVelocitySensitivity
            && Mathf.Abs(a.angularVelocity - b.angularVelocity) < localAngularVelocitySensitivity;
    }

    IEnumerator SubscribeToPhysics()
    {
        PhysicsUpdate? previous = null;
        while (true)
        {
            var current = new PhysicsUpdate(NetworkTime.time, rigidbody);
            if (previous == null || !Approximately(previous.Value, current))
            {
                BroadcastPhysicsUpdate(current);
                previous = current;
            }

            yield return new WaitForFixedUpdate();
        }
    }

    private void BroadcastPhysicsUpdate(PhysicsUpdate update)
    {
        if (isServer)
        {
            // Debug.Log($"Server broadcast for {this}: {update}");
            RpcReceivePhysicsUpdate(update);
        }
        else
        {
            // Debug.Log($"Client broadcast for {this}: {update}");
            CmdBroadcastPhysicsUpdate(update);
        }
    }

    [Command(channel = Channels.DefaultUnreliable)]
    private void CmdBroadcastPhysicsUpdate(PhysicsUpdate update)
    {
        ApplyUpdate(update);
        RpcReceivePhysicsUpdate(update);
    }

    [ClientRpc(excludeOwner = true, channel = Channels.DefaultUnreliable)]
    private void RpcReceivePhysicsUpdate(PhysicsUpdate update)
    {
        // Debug.Log($"Received broadcast for {this}: {update}");
        ApplyUpdate(update);
    }

    private void ApplyUpdate(PhysicsUpdate update)
    {
        double currentTime = NetworkTime.time;
        double timeDelta = currentTime - update.networkTime;

        var current = new PhysicsUpdate(currentTime, rigidbody);
        PhysicsUpdate extrapolated = update.Scale(timeDelta);
        if (Approximately(current, update) || Approximately(current, extrapolated))
        {
            Debug.Log($"Skipping redundant physics update");
            return;
        }

        Debug.Log($"timeDelta: {timeDelta} Applying physics update: {extrapolated} vs. proposed {update} vs. current {current}");
        rigidbody.MovePosition(extrapolated.position);
        rigidbody.MoveRotation(extrapolated.rotation);
        rigidbody.velocity = extrapolated.velocity;
        rigidbody.angularVelocity = extrapolated.angularVelocity;
    }
}
