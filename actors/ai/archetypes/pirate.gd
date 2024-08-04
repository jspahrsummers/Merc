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
enum State {
    ## Patrolling around, waiting to detect a target.
    PATROL,

    ## Engaging a target.
    ENGAGE,

    ## Retreating from the target.
    RETREAT,
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
    self._ship.hull.changed.connect(_on_damage_received)
    self._ship.shield.changed.connect(_on_damage_received)

func _select_new_patrol_target() -> void:
    self._patrol_target = MathUtils.random_unit_vector() * self.patrol_radius

func _physics_process(delta: float) -> void:
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
        self._current_state = State.PATROL
        return

    if not self._pointing_in_direction(self._desired_direction()):
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
    
    if distance <= self.fire_range:
        for weapon_mount in self._ship.weapon_mounts:
            weapon_mount.fire()

func _retreat_behavior(_delta: float) -> void:
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

func _on_damage_received() -> void:
    # TODO: This isn't necessarily the actual attacker. Need to implement a way
    # to figure out who fired a weapon.
    var attacker := self._find_closest_target()
    if attacker == null:
        return
    
    if attacker != self._ship.targeting_system.target:
        self._ship.targeting_system.target = attacker
        self._current_state = State.ENGAGE
