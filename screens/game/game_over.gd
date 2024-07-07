extends AcceptDialog

@export var main_menu_scene: PackedScene

func _on_confirmed() -> void:
    get_tree().change_scene_to_packed(self.main_menu_scene)

func _on_player_ship_destroyed(_player: Player) -> void:
    self.show()
