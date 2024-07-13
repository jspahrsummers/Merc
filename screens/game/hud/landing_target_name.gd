extends Label

@export var pick_sound: AudioStreamPlayer

func _on_landing_target_changed(_player: Player, target: PlanetInstance) -> void:
    if target == null:
        self.text = ""
    else:
        self.text = target.planet.name if target.planet else String(target.name)
        self.pick_sound.play()
