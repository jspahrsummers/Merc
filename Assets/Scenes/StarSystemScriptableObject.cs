using System.Collections.Generic;
using UnityEngine;

using VectorExtensions;

[CreateAssetMenu(menuName = "Star System")]
public sealed class StarSystemStateScriptableObject : ScriptableObject
{
    public Vector2 galaxyPosition;
    public List<StarSystemStateScriptableObject> adjacentSystems;

    public float AngleToSystem(StarSystemStateScriptableObject otherSystem)
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