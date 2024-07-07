extends Label

@export var pick_sound: AudioStreamPlayer

func _on_jump_destination_changed(destination: StarSystem) -> void:
    if destination == null:
        self.text = ""
    else:
        self.text = destination.name
        self.pick_sound.play()
