extends Label

func _on_jump_destination_loaded(new_system_instance: StarSystemInstance) -> void:
    self.text = new_system_instance.name
