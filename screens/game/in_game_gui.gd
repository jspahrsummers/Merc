extends CanvasLayer

@export var galaxy_map_window: Window
@export var exit_dialog: Window

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_galaxy_map"):
       self.galaxy_map_window.visible = true
    elif event.is_action_pressed("exit"):
        self.exit_dialog.visible = true
