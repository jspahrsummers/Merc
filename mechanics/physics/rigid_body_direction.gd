extends Node3D
class_name RigidBodyDirection

## Attaches to a [RigidBody3D] to implement rotation toward a specific direction.
##
## [b]This script expects the parent node to be a [RigidBody3D].[/b]

## The thruster determining the spin speed.
@export var spin_thruster: SpinThruster

## A vector representing the direction to rotate toward, or zero to stop rotating.
var direction: Vector3 = Vector3.ZERO:
    set(value):
        direction = value

## The [RigidBody3D] to rotate.
@onready var _rigid_body := get_parent() as RigidBody3D

## An optional [Battery] to power the thruster from.
var battery: Battery

func _physics_process(delta: float) -> void:
    if self.direction.is_zero_approx():
        return

    if self.battery and is_zero_approx(self.battery.power):
        return

    var desired_basis := Basis.looking_at(self.direction)
    if self._rigid_body.global_basis.is_equal_approx(desired_basis):
        return

    if not self._rigid_body.angular_velocity.is_zero_approx():
        self._rigid_body.angular_velocity = Vector3.ZERO

    # This may consume more power than necessary, if less than a full rotation
    # step is still needed. This is an acceptable cost for the simplicity of
    # this function, also taking into account that the error will be bounded by
    # `delta`.
    var desired_power := self.spin_thruster.power_consumption_rate * delta
    var consumed_power := self.battery.consume_up_to(desired_power) if self.battery else desired_power
    var consumed_percentage := consumed_power / desired_power

    self._rigid_body.global_basis = self._rigid_body.global_basis.slerp(desired_basis, self.spin_thruster.turning_rate * delta * consumed_percentage)
