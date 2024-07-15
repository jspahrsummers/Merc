extends CanvasLayer

@export var galaxy_map_window: Window
@export var game_over_scene: PackedScene
@export var exit_dialog: Window

func _on_player_ship_destroyed(_player: Player) -> void:
    var game_over_window: Window = game_over_scene.instantiate()
    self.add_child(game_over_window)
    game_over_window.show()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_galaxy_map"):
       self.galaxy_map_window.visible = true
    elif event.is_action_pressed("exit"):
        self.exit_dialog.visible = true
