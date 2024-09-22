@tool
extends EditorPlugin

var inspector_plugin

func _enter_tree():
    inspector_plugin = preload("res://addons/galaxy_map_editor/galaxy_map_editor.gd").new()
    add_inspector_plugin(inspector_plugin)

func _exit_tree():
    remove_inspector_plugin(inspector_plugin)