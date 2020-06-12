using System.Collections.Generic;
using UnityEngine;

using VectorExtensions;

[CreateAssetMenu(menuName = "Star System")]
public sealed class StarSystemScriptableObject : ScriptableObject
{
    public Vector2 galaxyPosition;
    public List<StarSystemScriptableObject> adjacentSystems = new List<StarSystemScriptableObject>();

    private static List<StarSystemScriptableObject> allSystems = new List<StarSystemScriptableObject>();

    public static IEnumerable<StarSystemScriptableObject> AllSystems()
    {
        return allSystems;
    }

    public float AngleToSystem(StarSystemScriptableObject otherSystem)
    {
        return galaxyPosition.AngleToward(otherSystem.galaxyPosition);
    }

    void OnEnable()
    {
        Debug.Assert(adjacentSystems.TrueForAll(system => system.adjacentSystems.Contains(this)));
        allSystems.Add(this);
    }

    void OnDisable()
    {
        allSystems.Remove(this);
    }
}