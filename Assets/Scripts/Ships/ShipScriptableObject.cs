using UnityEngine;

[CreateAssetMenu(menuName = "Gameplay/Ship")]
public class ShipScriptableObject : ScriptableObject
{
    public Destructible baseDestructible;
    public float mass = 1;
    public float turnSpeed;
    public float torque;
    public float thrust;
    public float fuelConsumption;
    public float fuelRegeneration;
    public float hyperspaceThrust;
    public float hyperspaceAngleTolerance;
    public float requiredHyperspaceVelocity;
    public float hyperspaceArrivalDistance;
}
