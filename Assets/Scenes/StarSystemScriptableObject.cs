using System.Collections.Generic;
using UnityEngine;

using VectorExtensions;

[CreateAssetMenu(menuName = "Star System")]
public sealed class StarSystemScriptableObject : ScriptableObject
{
    public Vector2 galaxyPosition;
    public List<StarSystemScriptableObject> adjacentSystems;

    private static List<StarSystemScriptableObject> allSystems = new List<StarSystemScriptableObject>();

    public static IEnumerable<StarSystemScriptableObject> AllSystems()
    {
        Debug.Log($"AllSystems");
        return allSystems;
    }

    public float AngleToSystem(StarSystemScriptableObject otherSystem)
    {
        float angle = galaxyPosition.AngleToward(otherSystem.galaxyPosition);
        Debug.Log($"Angle from {this} to {otherSystem}: {angle}");
        return angle;
    }

    void OnEnable()
    {
        Debug.Log($"{this} enable");
        allSystems.Add(this);
        Debug.Assert(adjacentSystems.TrueForAll(system => system.adjacentSystems.Contains(this)));
    }

    void OnDisable()
    {
        Debug.Log($"{this} disable");
        allSystems.Remove(this);
    }
}