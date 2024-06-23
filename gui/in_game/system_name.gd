extends Label

func _on_jump_destination_loaded(system: StarSystem) -> void:
    self.text = system.name
