using UnityEngine;

[CreateAssetMenu(menuName = "Gameplay/Ship")]
public class ShipScriptableObject : ScriptableObject
{
    public Destructible baseDestructible;

    [Tooltip("Mass of this ship in tonnes (used in physics calculations)")]
    public float mass = 1;

    [Tooltip("Number of degrees this ship is able to rotate per second")]
    public float turnSpeed;

    // TODO: Unify with turnSpeed somehow?
    [Tooltip("Kilonewtons applied per second of turning")]
    public float torque;

    [Tooltip("Kilonewtons applied per second of thrusting")]
    public float thrust;

    [Tooltip("Normalized percentage [0,1] of fuel consumed per second while thrusting")]
    public float fuelConsumption;

    [Tooltip("Normalized percentage [0,1] of fuel produced per second")]
    public float fuelRegeneration;

    [Tooltip("Kilonewtons applied per second when entering hyperspace")]
    public float hyperspaceThrust;

    [Tooltip("Degrees of error permitted when rotating for hyperspace")]
    public float hyperspaceAngleTolerance;

    [Tooltip("Velocity in meters/second required to successfully jump into hyperspace")]
    public float requiredHyperspaceVelocity;

    [Tooltip("Distance in meters (from system center) that this ship arrives at from hyperspace")]
    public float hyperspaceArrivalDistance;
}
