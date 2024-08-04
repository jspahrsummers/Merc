extends ConfirmationDialog

@export var main_menu_scene: PackedScene

func _on_confirmed() -> void:
    SaveGame.save(self.get_tree(), SaveGame.SAVE_GAMES_DIRECTORY.path_join("autosave.json"))
    get_tree().change_scene_to_packed(self.main_menu_scene)

func _on_canceled() -> void:
    self.queue_free()
