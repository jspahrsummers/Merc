extends Label

@export var pick_sound: AudioStreamPlayer

func _on_landing_target_changed(_player: Player, target: Celestial) -> void:
    if target == null:
        self.text = ""
    else:
        self.text = target.port.name if target.port else String(target.name)
        self.pick_sound.play()
