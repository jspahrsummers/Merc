extends Control

@export var control_scheme_button: OptionButton
@export var ui_scale_range: Range
@export var windowed_button: CheckButton

func _ready() -> void:
    UserPreferences.preferences_updated.connect(_on_preferences_updated)
    self._on_preferences_updated()

func _on_preferences_updated() -> void:
    self.control_scheme_button.selected = UserPreferences.control_scheme
    self.ui_scale_range.set_value_no_signal(UserPreferences.ui_scale * 100)
    self.windowed_button.set_pressed_no_signal(UserPreferences.windowed)

func _on_revert_button_pressed() -> void:
    UserPreferences.reload()

func _on_save_button_pressed() -> void:
    UserPreferences.save()

func _on_control_scheme_item_selected(index: int) -> void:
    UserPreferences.control_scheme = index as UserPreferences.ControlScheme

func _on_ui_scale_changed(value: float) -> void:
    UserPreferences.ui_scale = value / 100

func _on_windowed_toggled(toggled_on: bool) -> void:
    UserPreferences.windowed = toggled_on
