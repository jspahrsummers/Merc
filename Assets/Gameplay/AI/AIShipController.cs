using UnityEngine;

public sealed class AIShipController : MonoBehaviour
{
    public ShipScriptableObject ship;
    public Vector2 destination;
    public float destinationTolerance;
    public float speedTolerance;
    public float rotationTolerance;

    private new Rigidbody2D rigidbody => GetComponent<Rigidbody2D>();

    private interface IState
    {
        IState FixedUpdate();
    }

    private struct MovingTowardDestinationState : IState
    {
        public AIShipController shipController;

        private ShipScriptableObject ship => shipController.ship;
        private Rigidbody2D rigidbody => shipController.rigidbody;
        private Vector2 destination => shipController.destination;

        public IState FixedUpdate()
        {
            if (Vector2.Distance(rigidbody.position, destination) <= shipController.destinationTolerance)
            {
                Debug.Log("Reached destination");
                return new DeceleratingAndStoppingState() { shipController = shipController };
            }

            Vector2 distance = destination - rigidbody.position;
            float destinationAngle = Mathf.Atan2(distance.y, distance.x) * Mathf.Rad2Deg - 90;

            if (Mathf.Repeat(rigidbody.rotation - destinationAngle, 360) > shipController.rotationTolerance)
            {
                float newAngle = Mathf.MoveTowardsAngle(rigidbody.rotation, destinationAngle, ship.turnSpeed * Time.deltaTime);
                rigidbody.angularVelocity = 0;
                rigidbody.MoveRotation(newAngle);
            }
            else
            {
                rigidbody.AddRelativeForce(Vector2.up * ship.thrust * Time.deltaTime);
            }

            return this;
        }
    }

    private struct DeceleratingAndStoppingState : IState
    {
        public AIShipController shipController;
        private ShipScriptableObject ship => shipController.ship;
        private Rigidbody2D rigidbody => shipController.rigidbody;

        public IState FixedUpdate()
        {
            if (Mathf.Abs(rigidbody.velocity.magnitude) <= shipController.speedTolerance)
            {
                Debug.Log("Decelerated to a stop");
                return null;
            }

            float velocityAngle = Vector2.SignedAngle(Vector2.up, rigidbody.velocity);
            float desiredAngle = velocityAngle + 180;

            if (Mathf.Repeat(rigidbody.rotation - desiredAngle, 360) > shipController.rotationTolerance)
            {
                float newAngle = Mathf.MoveTowardsAngle(rigidbody.rotation, desiredAngle, ship.turnSpeed * Time.deltaTime);
                rigidbody.angularVelocity = 0;
                rigidbody.MoveRotation(newAngle);
            }
            else
            {
                rigidbody.AddRelativeForce(Vector2.up * ship.thrust * Time.deltaTime);
            }

            return this;
        }
    }

    private IState state;

    void Start()
    {
        state = new MovingTowardDestinationState() { shipController = this };
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        Debug.Log($"Collision between {this} and {other}");
        if (state == null)
        {
            state = new DeceleratingAndStoppingState { shipController = this };
        }
    }

    private IState IdleStateFixedUpdate()
    {
        if (Vector2.Distance(rigidbody.position, destination) > destinationTolerance)
        {
            return new MovingTowardDestinationState() { shipController = this };
        }

        return null;
    }

    void FixedUpdate()
    {
        state = (state == null ? IdleStateFixedUpdate() : state.FixedUpdate());
    }
}
