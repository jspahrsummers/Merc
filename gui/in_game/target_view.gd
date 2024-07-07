extends Node3D
class_name TargetView

@export var mesh_instance: MeshInstance3D

var mesh_to_render: Mesh:
    set(value):
        self.mesh_instance.mesh = value
