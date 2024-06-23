extends AnimatedSprite3D

## An audio clip to play when this object enters the scene.
@export var audio: AudioStreamPlayer3D

func _ready() -> void:
    self.animation_finished.connect(_on_animation_finished)
    self.audio.finished.connect(_on_audio_finished)

func _enter_tree() -> void:
    self.play()

func _on_animation_finished() -> void:
    if !self.audio.playing:
        self.queue_free()

func _on_audio_finished() -> void:
    if !self.is_playing():
        self.queue_free()
