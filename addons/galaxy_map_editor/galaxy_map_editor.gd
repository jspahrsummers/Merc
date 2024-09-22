extends EditorInspectorPlugin

func _can_handle(object):
    return object is Galaxy

func _parse_begin(object):
    if not (object is Galaxy):
        return false

    var galaxy_map = preload("res://addons/galaxy_map_editor/galaxy_map_visualization.gd").new()
    galaxy_map.galaxy = object
    add_custom_control(galaxy_map)
    return false
