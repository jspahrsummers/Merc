@tool
extends EditorPlugin

var _plugin: EditorInspectorPlugin

func _enter_tree() -> void:
	self._plugin = preload ("res://addons/star_system_preview/star_system_editor.gd").new()
	self.add_inspector_plugin(self._plugin)

func _exit_tree() -> void:
	self.remove_inspector_plugin(self._plugin)
