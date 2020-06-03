using UnityEngine;

public class PlanetController : MonoBehaviour
{
    public PlanetScriptableObject planet;

    public void OnMouseDown()
    {
        Debug.Log($"{planet} clicked");
    }
}
