using UnityEngine;

using RigidbodyExtensions;

[CreateAssetMenu(menuName = "Gameplay/AI States/Moving Toward Destination")]
public sealed class MovingTowardDestinationState : State
{
    public Vector2 destination;
    public float destinationTolerance;
    public float rotationTolerance;
    public Transition success;

    public override Transition? ShipFixedUpdate(ShipScriptableObject ship, Rigidbody2D rigidbody)
    {
        if (Vector2.Distance(rigidbody.position, destination) <= destinationTolerance)
        {
            Debug.Log("Reached destination");
            return success;
        }

        Vector2 distance = destination - rigidbody.position;
        float destinationAngle = Mathf.Atan2(distance.y, distance.x) * Mathf.Rad2Deg - 90;

        if (Mathf.Repeat(rigidbody.rotation - destinationAngle, 360) > rotationTolerance)
        {
            rigidbody.RotateToward(destinationAngle, ship.turnSpeed * Time.deltaTime);
        }
        else
        {
            rigidbody.AddRelativeForce(Vector2.up * ship.thrust * Time.deltaTime);
        }

        return null;
    }
}