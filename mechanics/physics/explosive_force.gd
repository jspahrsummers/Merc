extends Area3D

## Creates an explosive force on all [RigidBody3D]s within the area of effect.

## The amount of impulse force to generate.
@export var force: float = 100

func _ready() -> void:
    # Wait for two physics frames, to ensure collisions have been computed.
    await self.get_tree().physics_frame
    await self.get_tree().physics_frame

    self._apply_force()
    self.queue_free()

func _apply_force() -> void:
    var explosion_center := self.global_position

    for body in self.get_overlapping_bodies():
        var rigid_body := body as RigidBody3D
        if not rigid_body:
            continue
        
        # Calculate the direction from explosion to the body
        var direction := (rigid_body.global_position - explosion_center).normalized()
        
        # Calculate the impulse vector
        var impulse := direction * self.force
        
        # Apply the impulse to the rigid body
        rigid_body.apply_impulse(impulse, explosion_center)

        # TODO: Damage CombatObjects in the region of the explosion too
