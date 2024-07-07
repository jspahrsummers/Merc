extends Control

enum ToggleState {
    NONE = -1,
    SETTINGS = 0,
    LICENSES = 1,
}

# We choose to have a string reference to the game scene here because we need
# circular references in some places (e.g., the game over dialog), and it will
# be much easier to detect breakage in _this_ flow than in something deeply
# nested within the game.
const MAIN_GAME_SCENE = "res://screens/game/game.tscn"

@export var content_container: Container

@export var settings_button: Button
@export var settings_scene: PackedScene

@export var licenses_button: Button
@export var licenses_scene: PackedScene

var _buttons_by_state: Dictionary
var _scenes_by_state: Dictionary
var _currently_toggled: ToggleState = ToggleState.NONE
var _current_view: Control = null

func _ready() -> void:
    # TODO: Use a custom Resource for this?
    self._buttons_by_state = {
        ToggleState.SETTINGS: self.settings_button,
        ToggleState.LICENSES: self.licenses_button,
    }

    self._scenes_by_state = {
        ToggleState.SETTINGS: self.settings_scene,
        ToggleState.LICENSES: self.licenses_scene,
    }

func _set_currently_toggled(index: ToggleState) -> void:
    if self._currently_toggled != ToggleState.NONE:
        self._buttons_by_state[self._currently_toggled].button_pressed = false
        self._current_view.queue_free()
    
    if index == self._currently_toggled or index == ToggleState.NONE:
        self._currently_toggled = ToggleState.NONE
    else:
        self._buttons_by_state[index].button_pressed = true
        self._currently_toggled = index

        var scene: PackedScene = self._scenes_by_state[index]
        var node: Control = scene.instantiate()
        self.content_container.add_child(node)
        self._current_view = node

func _on_new_game_button_pressed() -> void:
    get_tree().change_scene_to_file(MAIN_GAME_SCENE)

func _on_settings_button_pressed() -> void:
    self._set_currently_toggled(ToggleState.SETTINGS)

func _on_licenses_button_pressed() -> void:
    self._set_currently_toggled(ToggleState.LICENSES)

func _on_exit_button_pressed() -> void:
    get_tree().quit()
