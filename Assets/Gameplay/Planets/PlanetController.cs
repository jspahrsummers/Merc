using UnityEngine;
using UnityEngine.EventSystems;

public class PlanetController : MonoBehaviour
{
    public PlanetScriptableObject planet;
    public GameObject targetSprite;

    private StarSystemController starSystemController => GameObject.FindWithTag("StarSystem").GetComponent<StarSystemController>();

    private bool _selected = false;
    public bool selected
    {
        get => _selected;
        set
        {
            _selected = value;
            targetSprite.SetActive(value);

            if (value)
            {
                starSystemController.OnPlanetSelected(this);
            }
        }
    }

    void Start()
    {
        starSystemController.AddPlanetController(this);
    }

    public void OnMouseDown()
    {
        selected = true;
    }
}
