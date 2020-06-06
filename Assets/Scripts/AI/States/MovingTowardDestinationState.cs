using UnityEngine;

using RigidbodyExtensions;
using VectorExtensions;

[CreateAssetMenu(menuName = "Gameplay/AI States/Moving Toward Destination")]
public sealed class MovingTowardDestinationState : State
{
    public Vector2 destination;
    public float destinationTolerance;
    public float speedTolerance;
    public Transition success;

    public override Transition? ShipFixedUpdate(ShipScriptableObject ship, Rigidbody2D rigidbody)
    {
        bool stopped = rigidbody.velocity.magnitude <= speedTolerance;
        bool atDestination = Vector2.Distance(rigidbody.position, destination) <= destinationTolerance;

        if (stopped && atDestination)
        {
            Debug.Log("Reached destination");
            return success;
        }

        // TODO: Handle existing velocity that is contradictory
        float angleTowardDestination = rigidbody.position.AngleToward(destination);
        float remainingTimeUntilDestination = rigidbody.TimeUntilPosition(destination);

        float forceWillApply = ship.thrust * Time.deltaTime;
        float forceRequiredToStop = rigidbody.ForceRequiredToStop().magnitude;

        float velocityAngle = Vector2.SignedAngle(Vector2.up, rigidbody.velocity);
        float oppositeAngle = velocityAngle + 180;

        float timeNeededToTurnAround = rigidbody.TimeUntilRotatedToward(oppositeAngle, ship.turnSpeed);
        float timeNeededToStopWithoutChanges = timeNeededToTurnAround + forceRequiredToStop / forceWillApply;
        float timeNeededToStopWithChanges = timeNeededToTurnAround + (forceRequiredToStop + forceWillApply) / forceWillApply + Time.fixedDeltaTime;

        if (remainingTimeUntilDestination > timeNeededToStopWithoutChanges)
        {
            // Rotate and thrust toward destination
            if (!rigidbody.IsRotatedToward(angleTowardDestination, ship.hyperspaceAngleTolerance))
            {
                rigidbody.RotateToward(angleTowardDestination, ship.turnSpeed * Time.deltaTime);
            }
            else if (remainingTimeUntilDestination > timeNeededToStopWithChanges)
            {
                rigidbody.AddRelativeForce(Vector2.up * ship.thrust);
            }
        }
        else
        {
            // Come to a stop
            if (rigidbody.IsRotatedToward(oppositeAngle, ship.hyperspaceAngleTolerance))
            {
                rigidbody.AddRelativeForce(Vector2.up * ship.thrust);
            }
            else
            {
                rigidbody.RotateToward(oppositeAngle, ship.turnSpeed * Time.deltaTime);
            }
        }

        return null;
    }
}