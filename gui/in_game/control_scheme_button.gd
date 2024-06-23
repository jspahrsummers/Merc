extends OptionButton

func _ready() -> void:
    UserPreferences.preferences_updated.connect(_update)
    self._update()

func _update() -> void:
    self.selected = UserPreferences.control_scheme

func _on_item_selected(index: int) -> void:
    UserPreferences.set_control_scheme(index)
