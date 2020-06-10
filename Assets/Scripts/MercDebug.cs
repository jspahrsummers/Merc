using UnityEngine;

public static class MercDebug
{
    [System.Diagnostics.Conditional("UNITY_ASSERTIONS")]
    public static void Invariant(bool condition, object message)
    {
        if (condition)
        {
            return;
        }

        Debug.LogAssertion(message);
        Debug.Break();
    }
}