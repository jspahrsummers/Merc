extends Control

@export var control_scheme_button: OptionButton
@export var ui_scale_range: Range
@export var display_mode_button: OptionButton
@export var tutorial_enabled_button: OptionButton
@export var bindings_list: ItemList
@export var anthropic_api_key_edit: TextEdit

enum DisplayMode {
    WINDOWED = 0,
    FULLSCREEN = 1
}

var _input_actions: Array[StringName] = []
var _current_action_being_rebound: String = ""

func _ready() -> void:
    UserPreferences.preferences_updated.connect(_on_preferences_updated)
    self._on_preferences_updated()

func _on_preferences_updated() -> void:
    self.control_scheme_button.selected = UserPreferences.control_scheme
    self.ui_scale_range.set_value_no_signal(UserPreferences.ui_scale * 100)
    self.display_mode_button.selected = DisplayMode.WINDOWED if UserPreferences.windowed else DisplayMode.FULLSCREEN
    self.tutorial_enabled_button.selected = 0 if UserPreferences.tutorial_enabled else 1
    self.anthropic_api_key_edit.text = UserPreferences.anthropic_api_key

    self._input_actions.clear()
    self.bindings_list.clear()

    for action in InputMap.get_actions():
        if action.begins_with("ui_"):
            # Skip default UI actions.
            continue

        self._input_actions.append(action)
        self.bindings_list.add_item(action.capitalize())

        var event := InputMap.action_get_events(action)[0]
        self.bindings_list.add_item(event.as_text())

func _on_revert_button_pressed() -> void:
    UserPreferences.reload()

func _on_save_button_pressed() -> void:
    UserPreferences.save()

func _on_control_scheme_item_selected(index: int) -> void:
    UserPreferences.control_scheme = index as UserPreferences.ControlScheme

func _on_ui_scale_changed(value: float) -> void:
    UserPreferences.ui_scale = value / 100

func _on_display_mode_button_item_selected(index: int) -> void:
    UserPreferences.windowed = index == DisplayMode.WINDOWED

func _on_tutorial_enabled_item_selected(index: int) -> void:
    UserPreferences.tutorial_enabled = index == 0

func _on_anthropic_api_key_changed() -> void:
    UserPreferences.anthropic_api_key = self.anthropic_api_key_edit.text

func _input(event: InputEvent) -> void:
    if self._current_action_being_rebound == "":
        return

    var key_event := event as InputEventKey
    var mouse_event := event as InputEventMouseButton
    if key_event or (mouse_event and mouse_event.pressed):
        if key_event and key_event.keycode == KEY_ESCAPE:
            UserPreferences.reset_action_bindings(self._current_action_being_rebound)
        else:
            UserPreferences.set_action_bindings(self._current_action_being_rebound, [event])

        self._current_action_being_rebound = ""
        get_viewport().set_input_as_handled()

func _on_bindings_list_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
    if index % 2 == 0 or self._current_action_being_rebound:
        return
    
    @warning_ignore("integer_division")
    self._current_action_being_rebound = self._input_actions[index / 2]
    self.bindings_list.set_item_text(index, "Press any key…")
