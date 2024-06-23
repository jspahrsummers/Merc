extends Ship

## AI for a ship that behaves like a pirate, attacking nearby ships on sight.

## The range (in m) in which other ships will be detected by the pirate.
@export var detection_range: float = 10.0

## The minimum range (in m) that this ship will try to maintain from its target.
@export var preferred_distance: float = 3.0

## The distance (in m) over which to make corrections while engaging the target.
@export var distance_hysteresis: float = 1.5

## The maximum range (in m) at which this ship will fire its weapon at the target.
@export var fire_range: float = 8.0

## For firing and thrusting, the tolerance (in degrees) for being slightly off-rotated.
@export var direction_tolerance_deg: float = 10.0

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

var _current_state := State.PATROL
var _direction_tolerance_rad: float
var _patrol_target := Vector3.ZERO

func _ready() -> void:
    super()
    self._direction_tolerance_rad = deg_to_rad(self.direction_tolerance_deg)
    self._select_new_patrol_target()
    self.ship_hull_changed.connect(_on_damage_received)
    self.ship_shield_changed.connect(_on_damage_received)

func _select_new_patrol_target():
    self._patrol_target = MathUtils.random_unit_vector() * self.patrol_radius

func _physics_process(delta: float):
    super(delta)

    if self.target == null:
        self._current_state = State.PATROL

    match _current_state:
        State.PATROL:
            self._patrol_behavior(delta)
        State.ENGAGE:
            self._engage_behavior(delta)
        State.RETREAT:
            self._retreat_behavior(delta)

func _desired_direction() -> Vector3:
    if self.target == null:
        return (self._patrol_target - self.global_transform.origin).normalized()
    else:
        var target_direction := (self.target.global_transform.origin - self.global_transform.origin).normalized()
        return target_direction if self._current_state != State.RETREAT else - target_direction

func _pointing_in_direction(direction: Vector3) -> bool:
    var current_direction = -self.global_transform.basis.z
    return current_direction.angle_to(direction) <= self._direction_tolerance_rad

func _patrol_behavior(delta: float):
    self.set_target(self._find_closest_ship())
    if self.target != null:
        self._current_state = State.ENGAGE
        return

    var direction_to_target = self._patrol_target - self.global_transform.origin
    if direction_to_target.length() < self.patrol_target_tolerance: # Close enough to current patrol point
        self._select_new_patrol_target()
    elif self._pointing_in_direction(direction_to_target.normalized()):
        self.thrust_step(1.0, delta)
        return
    
    self.thrust_stopped()

func _engage_behavior(delta: float):
    if self.target == null:
        self._current_state = State.PATROL
        return

    var distance = self.global_transform.origin.distance_to(self.target.global_transform.origin)
    var desired_direction = self._desired_direction()

    if not self._pointing_in_direction(desired_direction):
        return

    if distance > self.preferred_distance + self.distance_hysteresis:
        self.thrust_step(1.0, delta)
    elif distance < self.preferred_distance - self.distance_hysteresis:
        self.thrust_stopped()
        self._current_state = State.RETREAT
    else:
        # Maintain distance
        if abs(distance - self.preferred_distance) > self.distance_hysteresis / 2:
            self.thrust_step(0.5, delta) # Use half thrust for small adjustments
        else:
            self.thrust_stopped()
    
    if distance <= self.fire_range:
        self.fire()

func _retreat_behavior(delta: float):
    if self.target == null:
        self._current_state = State.PATROL
        return

    var distance = self.global_transform.origin.distance_to(self.target.global_transform.origin)
    if self._pointing_in_direction(self._desired_direction()):
        self.thrust_step(1.0, delta)
    else:
        self.thrust_stopped()
    
    if distance >= self.preferred_distance:
        self._current_state = State.ENGAGE

func _find_closest_ship() -> Ship:
    var ships := self.get_tree().get_nodes_in_group("ships")
    ships.erase(self)

    var closest_ship: Ship = null
    var closest_distance := self.detection_range

    for ship in ships:
        var distance := self.global_transform.origin.distance_to(ship.global_transform.origin)
        if distance < closest_distance:
            closest_distance = distance
            closest_ship = ship

    return closest_ship

func _on_damage_received(_ship: Ship):
    # TODO: This isn't necessarily the actual attacker. Need to implement a way
    # to figure out who fired a weapon.
    var attacker = self._find_closest_ship()
    if attacker == null:
        return
    
    if attacker != self.target:
        self.set_target(attacker)
        self._current_state = State.ENGAGE

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    var desired_basis = Basis.looking_at(self._desired_direction())
    if state.transform.basis.is_equal_approx(desired_basis):
        return
    
    if not self.consume_turning_energy(state.get_step()):
        return

    state.transform.basis = state.transform.basis.slerp(desired_basis, self.ship_def.torque * state.get_step())
