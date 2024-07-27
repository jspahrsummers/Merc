
extends Node3D
class_name Trader

## AI for a ship that behaves like a trader, moving between star systems to conduct trade.
##
## [b]This script expects the parent node to be a [Ship].[/b]

## The range (in m) in which other ships will be detected by the trader.
@export var detection_range: float = 15.0

## The minimum range (in m) that this ship will try to maintain from potential threats.
@export var safe_distance: float = 10.0

## For thrusting and changing direction, the tolerance for being slightly off-rotated.
@export_range(0, 180, 1, "radians_as_degrees") var direction_tolerance: float = deg_to_rad(10.0)

## The trader's navigation system.
@export var navigation: AINavigation

## State machine for this AI. How it behaves will depend on which state it's in at any given time.
enum State {
    ## Traveling to the next star system.
    TRAVEL,

    ## Conducting trade at the current star system.
    TRADE,

    ## Fleeing from a potential threat.
    FLEE,
}

@onready var _ship := self.get_parent() as Ship
var _current_state := State.TRAVEL
var _current_system: StarSystem
var _destination_system: StarSystem
var _trade_timer: float = 0.0
var _flee_target: CombatObject

## The approximate time (in seconds) the trader spends at each system.
const TRADE_TIME: float = 60.0

func _ready() -> void:
    self._ship.radar_object.iff = RadarObject.IFF.NEUTRAL
    self._current_system = StarSystemInstance.star_system_instance_for_node(self).star_system
    self._select_new_destination()

    # Connect to damage events
    self._ship.combat_object.hull.changed.connect(_on_damage_received)
    self._ship.combat_object.shield.changed.connect(_on_damage_received)

func _physics_process(delta: float) -> void:
    match _current_state:
        State.TRAVEL:
            self._travel_behavior(delta)
        State.TRADE:
            self._trade_behavior(delta)
        State.FLEE:
            self._flee_behavior(delta)

    self._ship.rigid_body_direction.direction = self._desired_direction()

func _travel_behavior(delta: float) -> void:
    var threat := self._detect_threat()
    if threat:
        self._current_state = State.FLEE
        self._flee_target = threat
        return

    if self._ship.hyperdrive_system.jumping:
        return

    if self.navigation.navigating:
        if self._pointing_in_direction(self._desired_direction()):
            self._ship.rigid_body_thruster.throttle = 1.0
        else:
            self._ship.rigid_body_thruster.throttle = 0.0
        return

    # We've reached the jump point
    if self._ship.hyperdrive_system.can_jump():
        self._ship.hyperdrive_system.jump_destination = self._destination_system
        self._ship.hyperdrive_system.jumping = true
    else:
        # TODO: Implement refueling logic
        print("Trader needs refueling")

func _trade_behavior(delta: float) -> void:
    self._trade_timer -= delta
    if self._trade_timer <= 0:
        self._current_state = State.TRAVEL
        self._select_new_destination()
        return

    # TODO: Implement actual trading logic here
    # For now, we'll just wait at the system

func _flee_behavior(delta: float) -> void:
    if not self._flee_target or self._flee_target.is_queued_for_deletion():
        self._current_state = State.TRAVEL
        return

    var direction_to_threat = self._flee_target.global_transform.origin - self._ship.global_transform.origin
    if direction_to_threat.length() > self.safe_distance:
        self._current_state = State.TRAVEL
        return

    if self._pointing_in_direction(self._desired_direction()):
        self._ship.rigid_body_thruster.throttle = 1.0
    else:
        self._ship.rigid_body_thruster.throttle = 0.0

func _desired_direction() -> Vector3:
    match _current_state:
        State.TRAVEL:
            return self.navigation.destination - self._ship.global_transform.origin
        State.FLEE:
            if self._flee_target:
                return self._ship.global_transform.origin - self._flee_target.global_transform.origin
    
    return Vector3.ZERO

func _pointing_in_direction(direction: Vector3) -> bool:
    var current_direction := - self._ship.global_transform.basis.z
    return current_direction.angle_to(direction) <= self.direction_tolerance

func _detect_threat() -> CombatObject:
    var closest_threat: CombatObject = null
    var closest_distance := self.detection_range

    for target in self._ship.targeting_system.get_available_targets():
        if target.radar_object.iff == RadarObject.IFF.HOSTILE:
            var distance := self._ship.global_transform.origin.distance_to(target.global_transform.origin)
            if distance < closest_distance:
                closest_distance = distance
                closest_threat = target

    return closest_threat

func _select_new_destination() -> void:
    var possible_destinations := self._current_system.connections.duplicate()
    possible_destinations.erase(self._destination_system.name if self._destination_system else "")
    
    if possible_destinations.is_empty():
        # If we've somehow ended up in a dead end, allow backtracking
        possible_destinations = self._current_system.connections.duplicate()

    var next_system_name: StringName = possible_destinations[randi() % possible_destinations.size()]
    self._destination_system = self._current_system.galaxy.get_ref().get_system(next_system_name)
    
    # Set the navigation destination to the jump point
    self.navigation.set_destination(MathUtils.random_unit_vector() * Player.HYPERSPACE_ARRIVAL_RADIUS)

func _on_damage_received() -> void:
    # When damaged, immediately try to flee
    self._current_state = State.FLEE
    self._flee_target = self._detect_threat()

func _on_hyperspace_jump_completed() -> void:
    self._current_system = self._destination_system
    self._current_state = State.TRADE
    self._trade_timer = TRADE_TIME
    # TODO: Implement actual trading logic here

