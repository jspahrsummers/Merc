using UnityEngine;

[CreateAssetMenu(menuName = "Gameplay/AI Personality")]
public sealed class Personality : ScriptableObject
{
    public State initialState;

    public Transition collisionTransition;
}