using System.Collections.Generic;
using UnityEngine;

using VectorExtensions;

[CreateAssetMenu(menuName = "Star System")]
public sealed class StarSystemScriptableObject : ScriptableObject
{
    public Vector2 galaxyPosition;
    public List<StarSystemScriptableObject> adjacentSystems;

    public float AngleToSystem(StarSystemScriptableObject otherSystem)
    {
        float angle = galaxyPosition.AngleToward(otherSystem.galaxyPosition);
        Debug.Log($"Angle from {this} to {otherSystem}: {angle}");
        return angle;
    }

    void Start()
    {
        Debug.Assert(adjacentSystems.TrueForAll(system => system.adjacentSystems.Contains(this)));
    }
}