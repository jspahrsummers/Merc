extends Node3D
class_name Trader

## AI for a ship that behaves like a trader, avoiding combat.
##
## [b]This script expects the parent node to be a [Ship].[/b]

# TODO: Deduplicate code with Pirate class.

## For thrusting, the tolerance (in degrees) for being slightly off-rotated.
@export_range(0, 180, 1, "radians_as_degrees") var direction_tolerance: float = deg_to_rad(10.0)

## The tolerance (in m) for hitting the destination point, before selecting a new one.
@export var destination_tolerance: float = 1.0

@onready var _ship := self.get_parent() as Ship
var _destination: Node3D = null

func _select_new_destination() -> void:
    var planets: Array[Node3D] = []
    planets.assign(self.get_tree().get_nodes_in_group("planets"))
    if self._destination:
        planets.erase(self._destination)
    
    self._destination = planets.pick_random() if planets else null

func _desired_direction() -> Vector3:
    if not self._destination:
        return Vector3.ZERO

    return (self._destination.global_position - self._ship.global_position).normalized()

func _pointing_in_direction(direction: Vector3) -> bool:
    var current_direction := - self._ship.global_transform.basis.z
    return current_direction.angle_to(direction) <= self.direction_tolerance

func _distance_to_destination() -> float:
    if not self._destination:
        return 0.0

    return self._ship.global_position.distance_to(self._destination.global_position)

func _physics_process(_delta: float) -> void:
    if not self._destination:
        self._select_new_destination()

    var desired_direction := self._desired_direction()
    self._ship.rigid_body_direction.direction = desired_direction

    if not self._pointing_in_direction(desired_direction):
        self._ship.rigid_body_thruster.throttle = 0.0
        return
    
    if self._distance_to_destination() > self.destination_tolerance:
        self._ship.rigid_body_thruster.throttle = 1.0
    else:
        self._ship.rigid_body_thruster.throttle = 0.0
        self._select_new_destination()
