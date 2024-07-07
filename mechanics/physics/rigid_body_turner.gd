extends Node3D
class_name RigidBodyTurner

## Attaches to a [RigidBody3D] to implement turning on demand.
##
## [b]This script expects the parent node to be a [RigidBody3D].[/b]

## The thruster determining the spin speed.
@export var spin_thruster: SpinThruster

## The [Battery] to power the thruster from.
@export var battery: Battery

## The amount of turning to apply, where 1.0 is full turning clockwise, and -1.0 is full turning counterclockwise.
var turning: float:
    set(value):
        turning = clampf(value, -1.0, 1.0)

## The [RigidBody3D] to rotate.
@onready var _rigid_body := get_parent() as RigidBody3D

func _physics_process(delta: float) -> void:
    if is_zero_approx(self.battery.power) or is_zero_approx(self.turning):
        return
    
    if not self._rigid_body.angular_velocity.is_zero_approx():
        self._rigid_body.angular_velocity = Vector3.ZERO
    
    var desired_power := self.spin_thruster.power_consumption_rate * absf(self.turning) * delta
    var power_consumed := self.battery.consume_up_to(desired_power)
    var magnitude := self.turning * (power_consumed / desired_power)
    self._rigid_body.basis = self._rigid_body.basis.rotated(Vector3.DOWN, self.spin_thruster.turning_rate * magnitude * delta)
