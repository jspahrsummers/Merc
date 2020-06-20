using UnityEngine;
using Mirror;

public sealed class AIShipController : NetworkBehaviour, IDamageable
{
    public ShipScriptableObject ship;
    public Destructible destructible;
    public ExplodableController explodable;
    public new Rigidbody2D rigidbody;
    public Personality personality;

    private State state;

    void Start()
    {
        MercDebug.EnforceField(ship);
        MercDebug.EnforceField(destructible);
        MercDebug.EnforceField(explodable);
        MercDebug.EnforceField(rigidbody);
        MercDebug.EnforceField(personality);

        state = personality.initialState;
        destructible = ShipUtilities.InitializeShip(ship, rigidbody);
    }

    public void ApplyDamage(Damage damage)
    {
        destructible.ApplyDamage(damage);
        if (destructible.IsDestroyed())
        {
            explodable.Explode();
        }
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
