extends Camera3D

## A node to automatically follow with the camera.
@export var follow_target: Node3D

func _process(_delta: float) -> void:
    var follow_origin := follow_target.global_position
    follow_origin.y = self.global_position.y
    self.global_position = follow_origin
