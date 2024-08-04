extends Node3D
class_name AINavigation

## Automatically navigates a [RigidBody3D] to a particular position using a [RigidBodyThruster] and a [RigidBodyDirection].

@export var rigid_body_thruster: RigidBodyThruster
@export var rigid_body_direction: RigidBodyDirection

## For thrusting, the tolerance for being slightly off-rotated.
@export_range(0, 180, 1, "radians_as_degrees") var direction_tolerance: float = deg_to_rad(5)

## The destination to navigate to.
@export var destination: Vector3

## The distance tolerance to consider the destination reached.
@export var arrival_distance_tolerance: float = 5.0

## The maximum velocity allowed when coming to a stop.
@export var stopping_velocity_tolerance: float = 0.1

## Whether to automatically start navigation on ready.
@export var auto_start: bool = true

## State machine for this AI.
##
## Note that these values are saved via [SaveGame], so be careful not to break backwards compatibility!
enum State {
    IDLE = 0,
    ROTATING_TO_ACCELERATE = 1,
    ACCELERATING_TOWARD_DESTINATION = 2,
    ROTATING_TO_DECELERATE = 3,
    DECELERATING_TO_STOP = 4,
}

var navigating: bool:
    set(value):
        if value == navigating:
            return

        navigating = value
        if navigating:
            self._state = State.ROTATING_TO_ACCELERATE
        else:
            self._state = State.IDLE

@onready var _rigid_body := rigid_body_thruster.get_parent() as RigidBody3D

var _state: State = State.IDLE
var _target_direction: Vector3

## Signal emitted when the destination is reached.
signal destination_reached(navigator: AINavigation)

func _ready() -> void:
    if self.auto_start:
        self.navigating = true

func _physics_process(_delta: float) -> void:
    if not self.navigating:
        return

    match self._state:
        State.IDLE:
            self._idle()
        State.ROTATING_TO_ACCELERATE:
            self._rotate_to_accelerate()
        State.ACCELERATING_TOWARD_DESTINATION:
            self._accelerate_toward_destination()
        State.ROTATING_TO_DECELERATE:
            self._rotate_to_decelerate()
        State.DECELERATING_TO_STOP:
            self._decelerate_to_stop()

func _idle() -> void:
    self.rigid_body_direction.direction = Vector3.ZERO
    self.rigid_body_thruster.throttle = 0.0

func _rotate_to_accelerate() -> void:
    self._target_direction = (self.destination - self._rigid_body.global_position).normalized()
    self.rigid_body_direction.direction = self._target_direction
    self.rigid_body_thruster.throttle = 0.0

    if self._pointing_in_direction(self._target_direction):
        self._state = State.ACCELERATING_TOWARD_DESTINATION

func _accelerate_toward_destination() -> void:
    self.rigid_body_thruster.throttle = 1.0

    var distance_to_destination := self._rigid_body.global_position.distance_to(self.destination)
    var stopping_distance := self._calculate_stopping_distance(self._rigid_body.linear_velocity.length())

    # Account for rotation time in stopping distance
    var rotation_time := self._estimate_rotation_time(-self._rigid_body.linear_velocity.normalized())
    var rotation_distance := self._rigid_body.linear_velocity.length() * rotation_time
    stopping_distance += rotation_distance

    if stopping_distance >= distance_to_destination:
        self._state = State.ROTATING_TO_DECELERATE

func _rotate_to_decelerate() -> void:
    self._target_direction = -self._rigid_body.linear_velocity.normalized()
    self.rigid_body_direction.direction = self._target_direction
    self.rigid_body_thruster.throttle = 0.0

    if self._pointing_in_direction(self._target_direction):
        self._state = State.DECELERATING_TO_STOP

func _decelerate_to_stop() -> void:
    self._target_direction = -self._rigid_body.linear_velocity.normalized()
    self.rigid_body_direction.direction = self._target_direction
    
    if self._pointing_in_direction(self._target_direction):
        self.rigid_body_thruster.throttle = 1.0
    else:
        self.rigid_body_thruster.throttle = 0.0

    var distance_to_destination := self._rigid_body.global_position.distance_to(self.destination)
    if distance_to_destination <= self.arrival_distance_tolerance and self._rigid_body.linear_velocity.length() <= self.stopping_velocity_tolerance:
        self.navigating = false
        self.rigid_body_thruster.throttle = 0.0

        print("Destination reached")
        self.destination_reached.emit(self)

func _pointing_in_direction(direction: Vector3) -> bool:
    var current_direction := -self._rigid_body.global_transform.basis.z
    return current_direction.angle_to(direction) <= self.direction_tolerance

func _calculate_stopping_distance(current_velocity: float) -> float:
    var acceleration := self.rigid_body_thruster.thruster.thrust_force / self._rigid_body.mass
    return (current_velocity * current_velocity) / (2 * acceleration)

func _estimate_rotation_time(target_direction: Vector3) -> float:
    var current_direction := -self._rigid_body.global_transform.basis.z
    var angle_to_rotate := current_direction.angle_to(target_direction)
    return angle_to_rotate / self.rigid_body_direction.spin_thruster.turning_rate

func set_destination(new_destination: Vector3) -> void:
    self.destination = new_destination
    self.navigating = true

## See [SaveGame].
func save_to_dict() -> Dictionary:
    var result := {}
    result["navigating"] = self.navigating
    result["state"] = self._state
    result["target_direction"] = SaveGame.serialize_vector3(self._target_direction)
    return result

## See [SaveGame].
func load_from_dict(dict: Dictionary) -> void:
    self.navigating = dict["navigating"]
    self._state = dict["state"]
    self._target_direction = SaveGame.deserialize_vector3(dict["target_direction"])
