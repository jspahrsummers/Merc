extends Node3D
class_name TargetView

@export var mesh_instance: MeshInstance3D

@export var material: Material

var mesh_to_render: Mesh:
    set(value):
        mesh_to_render = value
        self._update_mesh_instance()

func _update_mesh_instance() -> void:
    self.mesh_instance.mesh = self.mesh_to_render
    for index in self.mesh_to_render.get_surface_count():
        self.mesh_instance.set_surface_override_material(index, self.material)
