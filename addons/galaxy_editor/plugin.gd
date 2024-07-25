@tool
extends EditorPlugin

var galaxy_editor_scene: PackedScene
var galaxy_editor_instance: Control

func _enter_tree():
    galaxy_editor_scene = preload ("res://addons/galaxy_editor/galaxy_editor.tscn")
    galaxy_editor_instance = galaxy_editor_scene.instantiate()
    get_editor_interface().get_editor_main_screen().add_child(galaxy_editor_instance)
    _make_visible(false)

func _exit_tree():
    if galaxy_editor_instance:
        galaxy_editor_instance.queue_free()

func _has_main_screen():
    return true

func _make_visible(visible):
    if galaxy_editor_instance:
        galaxy_editor_instance.visible = visible

func _get_plugin_name():
    return "Galaxy"

func _get_plugin_icon():
    return get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons")
