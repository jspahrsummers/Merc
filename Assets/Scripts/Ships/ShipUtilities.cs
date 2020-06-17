using UnityEngine;

public static class ShipUtilities
{
    public static Destructible InitializeShip(ShipScriptableObject ship, Rigidbody2D rigidbody)
    {
        Debug.Log($"Overriding {rigidbody} mass to {ship.mass}");
        rigidbody.mass = ship.mass;

        Destructible destructible = ship.baseDestructible;
        Debug.Assert(!destructible.IsDestroyed());
        return destructible;
    }
}