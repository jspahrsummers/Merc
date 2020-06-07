using UnityEngine;
using UnityEngine.Events;

public sealed class PlanetController : MonoBehaviour
{

    [System.Serializable]
    public sealed class SelectedEvent : UnityEvent<PlanetController> { }

    public PlanetScriptableObject planet;
    public GameObject targetSprite;
    public SelectedEvent selectedEvent = new SelectedEvent();

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
                selectedEvent.Invoke(this);
            }
        }
    }

    public void OnMouseDown()
    {
        selected = true;
    }
}
