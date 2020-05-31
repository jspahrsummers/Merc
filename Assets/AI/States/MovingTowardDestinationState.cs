using UnityEngine;

using RigidbodyExtensions;
using VectorExtensions;

[CreateAssetMenu(menuName = "Gameplay/AI States/Moving Toward Destination")]
public sealed class MovingTowardDestinationState : State
{
    public Vector2 destination;
    public float destinationTolerance;
    public float rotationTolerance;
    public float speedTolerance;
    public Transition success;

    private bool IsRotatedToward(Rigidbody2D rigidbody, float desiredAngle)
    {
        return Mathf.Repeat(rigidbody.rotation - desiredAngle, 360) < rotationTolerance;
    }

    public override Transition? ShipFixedUpdate(ShipScriptableObject ship, Rigidbody2D rigidbody)
    {
        bool stopped = rigidbody.velocity.magnitude <= speedTolerance;
        bool atDestination = Vector2.Distance(rigidbody.position, destination) <= destinationTolerance;

        if (stopped && atDestination)
        {
            Debug.Log("Reached destination");
            return success;
        }

        float angleTowardDestination = rigidbody.position.AngleToward(destination);
        float remainingTimeUntilDestination = rigidbody.TimeUntilPosition(destination);

        float forceWillApply = ship.thrust * Time.deltaTime;
        float forceRequiredToStop = rigidbody.ForceRequiredToStop().magnitude;

        float timeNeededToTurnAround = rigidbody.TimeUntilRotatedToward(angleTowardDestination + 180, ship.turnSpeed);
        float timeNeededToStopWithoutChanges = timeNeededToTurnAround + forceRequiredToStop / forceWillApply;
        float timeNeededToStopWithChanges = timeNeededToTurnAround + (forceRequiredToStop + forceWillApply) / forceWillApply + Time.fixedDeltaTime;

        if (remainingTimeUntilDestination > timeNeededToStopWithoutChanges)
        {
            // Rotate and thrust toward destination
            if (!IsRotatedToward(rigidbody, angleTowardDestination))
            {
                rigidbody.RotateToward(angleTowardDestination, ship.turnSpeed * Time.deltaTime);
            }
            else if (remainingTimeUntilDestination > timeNeededToStopWithChanges)
            {
                rigidbody.AddRelativeForce(Vector2.up * ship.thrust * Time.deltaTime);
            }
        }
        else
        {
            // Come to a stop
            float velocityAngle = Vector2.SignedAngle(Vector2.up, rigidbody.velocity);
            float oppositeAngle = velocityAngle + 180;
            if (IsRotatedToward(rigidbody, oppositeAngle))
            {
                rigidbody.AddRelativeForce(Vector2.up * ship.thrust * Time.deltaTime);
            }
            else
            {
                rigidbody.RotateToward(oppositeAngle, ship.turnSpeed * Time.deltaTime);
            }
        }

        return null;
    }
}