extends Label

@export var pick_sound: AudioStreamPlayer

func _on_jump_destination_changed(hyperdrive_system: HyperdriveSystem) -> void:
    if hyperdrive_system.jump_destination == null:
        self.text = ""
    else:
        self.text = hyperdrive_system.jump_destination.name
        self.pick_sound.play()
