extends Node3D
class_name Pirate

## AI for a ship that behaves like a pirate, attacking nearby ships on sight.
##
## [b]This script expects the parent node to be a [Ship].[/b]

## The range (in m) in which other ships will be detected by the pirate.
@export var detection_range: float = 10.0

## The minimum range (in m) that this ship will try to maintain from its target.
@export var preferred_distance: float = 3.0

## The distance (in m) over which to make corrections while engaging the target.
@export var distance_hysteresis: float = 1.5

## The maximum range (in m) at which this ship will fire its weapon at the target.
@export var fire_range: float = 8.0

## For firing and thrusting, the tolerance for being slightly off-rotated.
@export_range(0, 180, 1, "radians_as_degrees") var direction_tolerance: float = deg_to_rad(10.0)

## Maximum radius (in m) from the system's center that the pirate will patrol.
@export var patrol_radius: float = 10.0

## The tolerance (in m) for hitting the patrol point, before selecting a new one.
@export var patrol_target_tolerance: float = 1.0

## State machine for this AI. How it behaves will depend on which state it's in at any given time.
##
## Note that these values are saved via [SaveGame], so be careful not to break backwards compatibility!
enum State {
    ## Patrolling around, waiting to detect a target.
    PATROL = 0,

    ## Engaging a target.
    ENGAGE = 1,

    ## Retreating from the target.
    RETREAT = 2,
}

@onready var _ship := self.get_parent() as Ship
var _current_state := State.PATROL
var _patrol_target := Vector3.ZERO

func _ready() -> void:
    self._ship.radar_object.iff = RadarObject.IFF.HOSTILE
    self._select_new_patrol_target()

    # Have to wait for the ship to be ready before we can start listening for damage events.
    self._connect_notifications.call_deferred()

func _connect_notifications() -> void:
    self._ship.combat_object.damaged.connect(_on_damaged)

func _select_new_patrol_target() -> void:
    self._patrol_target = MathUtils.random_unit_vector() * self.patrol_radius

func _physics_process(delta: float) -> void:
    if self._ship.controls_disabled():
        self._ship.set_firing(false)
        return

    if not self._ship.targeting_system.target:
        self._current_state = State.PATROL

    match _current_state:
        State.PATROL:
            self._patrol_behavior(delta)
        State.ENGAGE:
            self._engage_behavior(delta)
        State.RETREAT:
            self._retreat_behavior(delta)

    self._ship.rigid_body_direction.direction = self._desired_direction()

func _desired_direction() -> Vector3:
    var target := self._ship.targeting_system.target
    if target:
        var target_direction := (target.global_transform.origin - self._ship.global_transform.origin).normalized()
        return target_direction if self._current_state != State.RETREAT else -target_direction
    else:
        return (self._patrol_target - self._ship.global_transform.origin).normalized()

func _pointing_in_direction(direction: Vector3) -> bool:
    var current_direction := -self._ship.global_transform.basis.z
    return current_direction.angle_to(direction) <= self.direction_tolerance

func _patrol_behavior(_delta: float) -> void:
    self._ship.set_firing(false)

    var target := self._find_closest_target()
    self._ship.targeting_system.target = target
    if target != null:
        self._current_state = State.ENGAGE
        return

    var direction_to_target := self._patrol_target - self._ship.global_transform.origin
    if direction_to_target.length() < self.patrol_target_tolerance: # Close enough to current patrol point
        self._select_new_patrol_target()
    elif self._pointing_in_direction(direction_to_target):
        self._ship.rigid_body_thruster.throttle = 1.0
        return

    self._ship.rigid_body_thruster.throttle = 0.0

func _engage_behavior(_delta: float) -> void:
    var target := self._ship.targeting_system.target
    if not target:
        self._ship.set_firing(false)
        self._current_state = State.PATROL
        return

    if not self._pointing_in_direction(self._desired_direction()):
        self._ship.set_firing(false)
        self._ship.rigid_body_thruster.throttle = 0.0
        return

    var distance := self._ship.global_transform.origin.distance_to(target.global_transform.origin)
    if distance > self.preferred_distance + self.distance_hysteresis:
        self._ship.rigid_body_thruster.throttle = 1.0
    elif distance < self.preferred_distance - self.distance_hysteresis:
        self._ship.rigid_body_thruster.throttle = 0.0
        self._current_state = State.RETREAT
    else:
        # Maintain distance
        if abs(distance - self.preferred_distance) > self.distance_hysteresis / 2:
            self._ship.rigid_body_thruster.throttle = 0.5 # Use half thrust for small adjustments
        else:
            self._ship.rigid_body_thruster.throttle = 0.0
    
    self._ship.set_firing(distance <= self.fire_range)

func _retreat_behavior(_delta: float) -> void:
    self._ship.set_firing(false)

    var target := self._ship.targeting_system.target
    if not target:
        self._current_state = State.PATROL
        return

    var distance := self._ship.global_transform.origin.distance_to(target.global_transform.origin)
    if self._pointing_in_direction(self._desired_direction()):
        self._ship.rigid_body_thruster.throttle = 1.0
    else:
        self._ship.rigid_body_thruster.throttle = 0.0
    
    if distance >= self.preferred_distance:
        self._current_state = State.ENGAGE

func _find_closest_target() -> CombatObject:
    var available_targets := self._ship.targeting_system.get_available_targets()
    available_targets.erase(self._ship.combat_object)

    var closest_target: CombatObject = null
    var closest_distance := self.detection_range

    for target in available_targets:
        var distance := self._ship.global_transform.origin.distance_to(target.global_transform.origin)
        if distance < closest_distance:
            closest_distance = distance
            closest_target = target

    return closest_target

func _on_damaged(_damage: Damage, attacker: CombatObject) -> void:
    if attacker == null or attacker == self._ship.targeting_system.target:
        return
    
    self._ship.targeting_system.target = attacker
    self._current_state = State.ENGAGE

## See [SaveGame].
func save_to_dict() -> Dictionary:
    var result := {}
    result["current_state"] = self._current_state
    result["patrol_target"] = SaveGame.serialize_vector3(self._patrol_target)
    return result

## See [SaveGame].
func load_from_dict(dict: Dictionary) -> void:
    self._current_state = dict["current_state"]
    self._patrol_target = SaveGame.deserialize_vector3(dict["patrol_target"])
