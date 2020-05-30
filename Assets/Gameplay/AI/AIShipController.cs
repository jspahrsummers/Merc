using UnityEngine;

public sealed class AIShipController : MonoBehaviour
{
    public float turnSpeed;
    public float thrust;
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
        private AIShipController ship;

        public MovingTowardDestinationState(AIShipController ship)
        {
            this.ship = ship;
            Debug.Log($"Starting to move toward destination {this.ship.destination}");
        }

        public IState FixedUpdate()
        {
            if (Vector2.Distance(ship.rigidbody.position, ship.destination) <= ship.destinationTolerance)
            {
                Debug.Log("Reached destination");
                return new DeceleratingAndStoppingState(ship);
            }

            Vector2 distance = ship.destination - ship.rigidbody.position;
            float destinationAngle = Mathf.Atan2(distance.y, distance.x) * Mathf.Rad2Deg - 90;

            if (Mathf.Repeat(ship.rigidbody.rotation - destinationAngle, 360) > ship.rotationTolerance)
            {
                float newAngle = Mathf.MoveTowardsAngle(ship.rigidbody.rotation, destinationAngle, ship.turnSpeed * Time.deltaTime);
                ship.rigidbody.angularVelocity = 0;
                ship.rigidbody.MoveRotation(newAngle);
            }
            else
            {
                ship.rigidbody.AddRelativeForce(Vector2.up * ship.thrust * Time.deltaTime);
            }

            return this;
        }
    }

    private struct DeceleratingAndStoppingState : IState
    {
        private AIShipController ship;

        public DeceleratingAndStoppingState(AIShipController ship)
        {
            this.ship = ship;
            Debug.Log("Starting to decelerate to a stop");
        }

        public IState FixedUpdate()
        {
            if (Mathf.Abs(ship.rigidbody.velocity.magnitude) <= ship.speedTolerance)
            {
                Debug.Log("Decelerated to a stop");
                return null;
            }

            float velocityAngle = Vector2.SignedAngle(Vector2.up, ship.rigidbody.velocity);
            float desiredAngle = velocityAngle + 180;

            if (Mathf.Repeat(ship.rigidbody.rotation - desiredAngle, 360) > ship.rotationTolerance)
            {
                float newAngle = Mathf.MoveTowardsAngle(ship.rigidbody.rotation, desiredAngle, ship.turnSpeed * Time.deltaTime);
                ship.rigidbody.angularVelocity = 0;
                ship.rigidbody.MoveRotation(newAngle);
            }
            else
            {
                ship.rigidbody.AddRelativeForce(Vector2.up * ship.thrust * Time.deltaTime);
            }

            return this;
        }
    }

    private IState state;

    void Start()
    {
        state = new MovingTowardDestinationState(this);
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        Debug.Log($"Collision between {this} and {other}");
        if (state == null)
        {
            state = new DeceleratingAndStoppingState(this);
        }
    }

    private IState IdleStateFixedUpdate()
    {
        if (Vector2.Distance(rigidbody.position, destination) > destinationTolerance)
        {
            return new MovingTowardDestinationState(this);
        }

        return null;
    }

    void FixedUpdate()
    {
        state = (state == null ? IdleStateFixedUpdate() : state.FixedUpdate());
    }
}
