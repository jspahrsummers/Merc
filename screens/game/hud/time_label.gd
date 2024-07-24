extends Label

@export var calendar: Calendar

func _process(_delta: float) -> void:
    self.text = self.calendar.get_gst()
