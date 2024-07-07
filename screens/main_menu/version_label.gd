extends Label

func _ready() -> void:
    self.text = "version %s" % ProjectSettings.get_setting_with_override("application/config/version")
