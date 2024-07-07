extends Button

@export var icon_normal: Texture2D
@export var icon_hover: Texture2D
@export var icon_pressed: Texture2D
@export var icon_disabled: Texture2D

func _ready() -> void:
    self._update_icon()

func _update_icon() -> void:
    match self.get_draw_mode():
        DRAW_NORMAL:
            self.icon = self.icon_normal
        DRAW_PRESSED, DRAW_HOVER_PRESSED:
            self.icon = self.icon_pressed
        DRAW_HOVER:
            self.icon = self.icon_hover
        DRAW_DISABLED:
            self.icon = self.icon_disabled

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouse:
        self._update_icon.call_deferred()

func _on_mouse_exited() -> void:
    self._update_icon.call_deferred()

func _on_toggled(_toggled_on: bool) -> void:
    self._update_icon.call_deferred()
