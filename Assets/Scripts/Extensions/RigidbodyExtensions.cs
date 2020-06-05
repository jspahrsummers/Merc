using UnityEngine;

using VectorExtensions;

namespace RigidbodyExtensions
{
    public static class Extension
    {
        public static bool IsRotatedToward(this Rigidbody2D rigidbody, float desiredAngle, float tolerance)
        {
            return Mathf.Repeat(rigidbody.rotation - desiredAngle, 360) < tolerance;
        }

        public static void RotateToward(this Rigidbody2D rigidbody, float desiredAngle, float turnSpeed)
        {
            float newAngle = Mathf.MoveTowardsAngle(rigidbody.rotation, desiredAngle, turnSpeed);
            rigidbody.angularVelocity = 0;
            rigidbody.MoveRotation(newAngle);
        }

        public static float TimeUntilRotatedToward(this Rigidbody2D rigidbody, float desiredAngle, float turnSpeed)
        {
            return Mathf.Repeat(rigidbody.rotation - desiredAngle, 360) / turnSpeed;
        }

        public static Vector2 ForceRequiredToStop(this Rigidbody2D rigidbody)
        {
            return -rigidbody.velocity * rigidbody.mass;
        }

        public static float TimeUntilPosition(this Rigidbody2D rigidbody, Vector2 position)
        {
            Vector2 remaining = position - rigidbody.position;
            Vector2 timeVector = remaining / rigidbody.velocity;
            return timeVector.AsTime();
        }
    }
}