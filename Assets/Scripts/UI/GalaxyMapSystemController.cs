using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public sealed class GalaxyMapSystemController : MonoBehaviour
{
    [System.Serializable]
    public sealed class ClickedEvent : UnityEvent<StarSystemScriptableObject>
    {
    }

    public Graphic graphic;
    public Button button;
    public Text label;
    public float mapScale = 1;
    public ClickedEvent clickedEvent = new ClickedEvent();

    private StarSystemScriptableObject _starSystem;
    public StarSystemScriptableObject starSystem
    {
        get => _starSystem;
        set
        {
            _starSystem = value;
            graphic.rectTransform.anchoredPosition = value.galaxyPosition * mapScale;
            label.text = value.name;
        }
    }

    void Start()
    {
        button.onClick.AddListener(() => clickedEvent.Invoke(starSystem));
    }

    public void Select()
    {
        button.Select();
    }
}
