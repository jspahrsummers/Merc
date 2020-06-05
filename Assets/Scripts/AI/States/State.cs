using UnityEngine;

public abstract class State : ScriptableObject
{
    public virtual Transition? ShipFixedUpdate(ShipScriptableObject ship, Rigidbody2D rigidbody)
    {
        return null;
    }
}