using UnityEngine;

[CreateAssetMenu(fileName = "Ship", menuName = "Gameplay/Ship")]
public class ShipScriptableObject : ScriptableObject
{
    public Destructible baseDestructible;
    public float mass;
    public float turnSpeed;
    public float torque;
    public float thrust;
    public float fuelConsumption;
    public float fuelRegeneration;
    public float hyperspaceThrust;
    public float requiredHyperspaceVelocity;
    public float hyperspaceArrivalDistance;
}
