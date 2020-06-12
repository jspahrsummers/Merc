using UnityEngine;

public sealed class AIShipController : AbstractShipController
{
    public Personality personality;

    private State state;

    override protected void Start()
    {
        base.Start();

        MercDebug.EnforceField(personality);
        state = personality.initialState;
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        Debug.Log($"Collision between {this} and {other}");
        ExecuteTransition(personality.collisionTransition);
    }

    private void ExecuteTransition(Transition transition)
    {
        Debug.Log($"AI state transition: {transition}");

        if (transition.actions != null)
        {
            foreach (var action in transition.actions)
            {
                // TODO: Run actions
            }
        }

        if (transition.nextState != null)
        {
            state = transition.nextState;
        }
    }

    void FixedUpdate()
    {
        Transition? transition = state.ShipFixedUpdate(ship, rigidbody);
        if (transition != null)
        {
            ExecuteTransition(transition.Value);
        }
    }
}
