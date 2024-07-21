extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
    return object is StarSystem

func _parse_end(object: Object) -> void:
    if not (object is StarSystem):
        return

    var control := preload ("res://addons/star_system_preview/star_system_preview.gd").new()
    control.star_system = object
    self.add_custom_control(control)
