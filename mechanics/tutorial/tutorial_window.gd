extends Window

@export var label: RichTextLabel
@export var previous_button: Button
@export var next_button: Button

## The current stage of the tutorial.
##
## Note that these values are saved via [SaveGame], so be careful about backwards compatibility!
enum Stage {
    INITIAL = 0,

    FINAL = 1000,
}

var _stage: Stage = Stage.INITIAL:
    set(value):
        if _stage == value:
            return
        
        _stage = value
        self._update()

func _ready() -> void:
    self._update()

func _update() -> void:
    self.previous_button.visible = self._stage != Stage.INITIAL
    self.next_button.text = "DONE" if self._stage == Stage.FINAL else "NEXT"

    match self._stage:
        Stage.INITIAL:
            self.label.text = """\
Welcome to your new ship! Let's get you acquainted with the basic controls."""
        
        Stage.FINAL:
            self.label.text = """\
TODO some patter about finishing the tutorial."""

func _on_close_requested() -> void:
    self.hide()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_tutorial"):
        self.get_viewport().set_input_as_handled()
        self.hide()

## See [SaveGame].
func save_to_dict() -> Dictionary:
    var result := {}
    result["stage"] = self._stage
    result["visible"] = self.visible
    return result

## See [SaveGame].
func load_from_dict(dict: Dictionary) -> void:
    self._stage = dict["stage"]
    self.visible = dict["visible"]

func _on_previous_button_pressed() -> void:
    assert(self._stage != Stage.INITIAL, "Previous button should not be clickable when on initial tutorial stage")

    var stages := Stage.values()
    var index := stages.find(self._stage)

    assert(index != -1, "Could not find current tutorial stage")
    self._stage = stages[index - 1]

func _on_next_button_pressed() -> void:
    if self._stage == Stage.FINAL:
        self.hide()
        return

    var stages := Stage.values()
    var index := stages.find(self._stage)

    assert(index != -1, "Could not find current tutorial stage")
    self._stage = stages[index + 1]
