extends Node

## Attaches to a [RigidBody3D] to initialize its properties from a [PhysicsProperties] resource.
##
## [b]This script expects the parent node to be a [RigidBody3D].[/b] This node will free itself after setting the properties.

@export var physics_properties: PhysicsProperties

func _ready() -> void:
    var rigid_body := get_parent() as RigidBody3D
    rigid_body.mass = self.physics_properties.mass

    self.queue_free()
