using UnityEngine;

[CreateAssetMenu(menuName = "Gameplay/Player State")]
public sealed class PlayerStateScriptableObject : ScriptableObject
{
    public long credits;

    public void Reset()
    {
        credits = 100000;
    }
}
