using UnityEngine;

using RigidbodyExtensions;

[CreateAssetMenu(menuName = "Gameplay/AI States/Decelerating and Stopping")]
public sealed class DeceleratingAndStoppingState : State
{
    public float speedTolerance;
    public float rotationTolerance;
    public Transition success;

    public override Transition? ShipFixedUpdate(ShipScriptableObject ship, Rigidbody2D rigidbody)
    {
        if (Mathf.Abs(rigidbody.velocity.magnitude) <= speedTolerance)
        {
            Debug.Log("Decelerated to a stop");
            return success;
        }

        float velocityAngle = Vector2.SignedAngle(Vector2.up, rigidbody.velocity);
        float desiredAngle = velocityAngle + 180;

        if (Mathf.Repeat(rigidbody.rotation - desiredAngle, 360) > rotationTolerance)
        {
            rigidbody.RotateToward(desiredAngle, ship.turnSpeed * Time.deltaTime);
        }
        else
        {
            rigidbody.AddRelativeForce(Vector2.up * ship.thrust * Time.deltaTime);
        }

        return null;
    }
}