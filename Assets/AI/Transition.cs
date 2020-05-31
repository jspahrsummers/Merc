using System.Collections.Generic;

[System.Serializable]
public struct Transition
{
    public State nextState;
    public List<Action> actions;

    public override string ToString()
    {
        return $"Transition({nextState})";
    }
}
