extends Label

func _process(_delta: float) -> void:
    self.text = "%d FPS" % Engine.get_frames_per_second()
