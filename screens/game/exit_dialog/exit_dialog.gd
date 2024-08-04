extends ConfirmationDialog

@export var main_menu_scene: PackedScene

func _on_confirmed() -> void:
    var result := SaveGame.save("autosave")
    if result != Error.OK:
        push_error("Failed to save game: %s" % result)

    get_tree().change_scene_to_packed(self.main_menu_scene)

func _on_canceled() -> void:
    self.queue_free()
