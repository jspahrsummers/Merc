extends AnimatedSprite3D

## An explosion effect.
##
## This sprite should have autoplay enabled.

## An audio clip that will play when this object enters the scene.
##
## This clip must be set to autoplay.
@export var audio: AudioStreamPlayer3D

func _ready() -> void:
    self.animation_finished.connect(_on_animation_finished)
    self.audio.finished.connect(_on_audio_finished)

func _on_animation_finished() -> void:
    if !self.audio.playing:
        self.queue_free()

func _on_audio_finished() -> void:
    if !self.is_playing():
        self.queue_free()
