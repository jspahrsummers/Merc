extends Node
class_name RigidBodyDirection

## Attaches to a [RigidBody3D] to implement rotation toward a specific direction.
##
## [b]This script expects the parent node to be a [RigidBody3D].[/b]

## The thruster determining the spin speed.
@export var spin_thruster: SpinThruster

## The [Battery] to power the thruster from.
@export var battery: Battery

## A vector representing the direction to rotate toward, or zero to stop rotating.
@export var direction: Vector3 = Vector3.ZERO:
    set(value):
        direction = value
        if not direction.is_zero_approx():
            self._desired_basis = Basis.looking_at(direction)

## The [RigidBody3D] to rotate.
@onready var _rigid_body := get_parent() as RigidBody3D

var _desired_basis := Basis.IDENTITY

func _physics_process(delta: float) -> void:
    if is_zero_approx(self.battery.power) or self.direction.is_zero_approx():
        return
    
    if not self._rigid_body.angular_velocity.is_zero_approx():
        self._rigid_body.angular_velocity = Vector3.ZERO
    
    var angle_delta := self._rigid_body.global_basis.get_rotation_quaternion().angle_to(self._desired_basis.get_rotation_quaternion())
    var max_turn := self.spin_thruster.turning_rate * delta
    var desired_turn := minf(max_turn, angle_delta) / max_turn
    var slerp_weight := desired_turn / max_turn

    var desired_power := self.spin_thruster.power_consumption_rate * slerp_weight
    var consumed_power := self.battery.consume_up_to(desired_power)
    var consumed_percentage := consumed_power / desired_power

    slerp_weight *= consumed_percentage
    self._rigid_body.global_basis = self._rigid_body.global_basis.slerp(self._desired_basis, slerp_weight)
