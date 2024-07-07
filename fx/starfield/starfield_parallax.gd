extends MeshInstance3D

## How much to dampen movement of the starfield below the game plane, while it moves in concert with the camera.
@export var starfield_parallax_dampening: float = 50

## The material rendering the starfield below the game plane.
@export var starfield_material: StandardMaterial3D

func _process(_delta: float) -> void:
    self.starfield_material.uv1_offset = Vector3(self.global_transform.origin.x, self.global_transform.origin.z, 0) / self.starfield_parallax_dampening
