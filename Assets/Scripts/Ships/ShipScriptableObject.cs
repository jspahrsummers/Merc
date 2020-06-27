using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

using DictionaryExtensions;

[CreateAssetMenu(menuName = "Gameplay/Ship")]
public class ShipScriptableObject : ScriptableObject
{

    [System.Serializable]
    public sealed class CargoChangedEvent : UnityEvent<ITransactable, int> { }

    public ShieldedHull baseDestructible;

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

    [Tooltip("Weapons available on this ship")]
    // TODO: Replace this with a weapon scriptable object, not that of projectiles.
    public List<ProjectileScriptableObject> weapons;

    [Tooltip("The total amount of capacity in this ship's cargo hold")]
    public int cargoCapacity;

    // FIXME: Unity doesn't serialize dictionaries
    private Dictionary<ITransactable, int> _allCargo = new Dictionary<ITransactable, int>();

    public IEnumerable<KeyValuePair<ITransactable, int>> allCargo => _allCargo;
    public int occupiedCargoSpace
    {
        get
        {
            int total = 0;
            foreach (var cargo in _allCargo)
            {
                total += cargo.Key.cargoSpaceRequired * cargo.Value;
            }

            return total;
        }
    }
    public int availableCargoSpace => cargoCapacity - occupiedCargoSpace;
    public CargoChangedEvent cargoChangedEvent = new CargoChangedEvent();

    public int GetCargo(ITransactable transactable)
    {
        return _allCargo.GetValueOrDefault(transactable, 0);
    }

    private void UpdateCargo(ITransactable transactable, int newQuantity)
    {
        MercDebug.Invariant(newQuantity >= 0, $"Cargo quantities should not be negative: {newQuantity}");
        if (newQuantity == 0)
        {
            _allCargo.Remove(transactable);
        }
        else
        {
            _allCargo[transactable] = newQuantity;
        }

        cargoChangedEvent.Invoke(transactable, newQuantity);
    }

    // Returns the amount actually added, subject to cargoCapacity.
    public int AddCargo(ITransactable transactable, int quantityToAdd)
    {
        if (quantityToAdd <= 0)
        {
            throw new ArgumentException($"Quantity to add should be positive: {quantityToAdd}");
        }

        int maximumQuantity = availableCargoSpace / transactable.cargoSpaceRequired;
        quantityToAdd = System.Math.Min(quantityToAdd, maximumQuantity);
        if (quantityToAdd == 0)
        {
            return 0;
        }

        int updatedQuantity = GetCargo(transactable) + quantityToAdd;
        UpdateCargo(transactable, updatedQuantity);

        MercDebug.Invariant(availableCargoSpace >= 0, "Available cargo space should never be negative");
        return quantityToAdd;
    }

    // Returns the amount actually removed.
    public int RemoveCargo(ITransactable transactable, int quantityToRemove)
    {
        if (quantityToRemove <= 0)
        {
            throw new ArgumentException($"Quantity to remove should be positive: {quantityToRemove}");
        }

        int existingQuantity = GetCargo(transactable);
        quantityToRemove = System.Math.Min(existingQuantity, quantityToRemove);

        int updatedQuantity = existingQuantity - quantityToRemove;
        UpdateCargo(transactable, updatedQuantity);

        MercDebug.Invariant(availableCargoSpace <= cargoCapacity, "Available cargo space should not exceed cargoCapacity");
        return quantityToRemove;
    }
}
