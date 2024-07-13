extends Node3D
class_name Player

## The player.
##
## [b]This script expects the parent node to be a [Ship].[/b]

@export var hyperspace_controller: HyperspaceController
@export var message_log: MessageLog
@export var landing_scene: PackedScene
@export var takeoff_sound: AudioStreamPlayer

@onready var ship := get_parent() as Ship

## Fires when the ship's hull changes (e.g., due to damage).
signal hull_changed(player: Player, hull: Hull)

## Fires when the ship's shield changes (e.g., due to damage).
signal shield_changed(player: Player, shield: Shield)

## Fires when the ship's power level changes.
signal power_changed(player: Player, battery: Battery)

## Fires when the player's ship is destroyed.
signal ship_destroyed(player: Player)

## Fires when the player changes their target.
signal target_changed(player: Player, target: CombatObject)

## Fires when the player changes their landing target.
signal landing_target_changed(player: Player, target: PlanetInstance)

## The current target for landing, if any.
var landing_target: PlanetInstance = null:
    set(value):
        if landing_target == value:
            return
        
        if landing_target:
            landing_target.targeted_by_player = false
        
        landing_target = value
        self.landing_target_changed.emit(self, landing_target)

        if landing_target:
            landing_target.targeted_by_player = true

## When using the "absolute" control scheme, this is the tolerance (in radians) for being slightly off-rotated while enabling thrusters.
const ABSOLUTE_DIRECTION_TOLERANCE_RAD = 0.1745

# TODO: Put this somewhere better (per ship?)
const HYPERSPACE_ARRIVAL_RADIUS = 8.0
const MAX_LANDING_DISTANCE = 2.0
const MAX_LANDING_VELOCITY = 4.0

func _ready() -> void:
    var turner: RigidBodyTurner = RigidBodyTurner.new()
    turner.spin_thruster = self.ship.rigid_body_direction.spin_thruster
    turner.battery = self.ship.rigid_body_direction.battery
    self.ship.add_child.call_deferred(turner)
    self.ship.rigid_body_turner = turner
    self.ship.radar_object.iff = RadarObject.IFF.SELF
    self.ship.targeting_system.is_player = true

    self.ship.combat_object.hull.changed.connect(_on_hull_changed)
    self.ship.combat_object.hull.hull_destroyed.connect(_on_hull_destroyed)
    self.ship.combat_object.shield.changed.connect(_on_shield_changed)
    self.ship.power_management_unit.battery.changed.connect(_on_power_changed)
    self.ship.targeting_system.target_changed.connect(_on_target_changed)

    # Initial notifications so the UI can update.
    self._on_hull_changed()
    self._on_shield_changed()
    self._on_power_changed()

func _on_hull_changed() -> void:
    self.hull_changed.emit(self, self.ship.combat_object.hull)

func _on_shield_changed() -> void:
    self.shield_changed.emit(self, self.ship.combat_object.shield)

func _on_power_changed() -> void:
    self.power_changed.emit(self, self.ship.power_management_unit.battery)

func _on_hull_destroyed(hull: Hull) -> void:
    assert(hull == self.ship.combat_object.hull, "Received hull_destroyed signal from incorrect hull")
    self.ship_destroyed.emit(self)

func _on_target_changed(targeting_system: TargetingSystem) -> void:
    self.target_changed.emit(self, targeting_system.target)

func _on_jump_destination_loaded(_system: StarSystem) -> void:
    self._reset_velocity()
    self.ship.position = MathUtils.random_unit_vector() * HYPERSPACE_ARRIVAL_RADIUS
    self.ship.targeting_system.target = null

func _next_system_connection() -> StarSystem:
    var current_destination_name: Variant = null
    if self.hyperspace_controller.jump_destination:
        current_destination_name = self.hyperspace_controller.jump_destination.name

    var next_destination_name: Variant = ArrayUtils.cycle_through(self.hyperspace_controller.current_system.connections, current_destination_name)
    return self.hyperspace_controller.galaxy.get_system(next_destination_name as StringName) if next_destination_name else null

func _next_target() -> CombatObject:
    var available_targets := self.ship.targeting_system.get_available_targets()
    available_targets.erase(self.ship.combat_object)
    return ArrayUtils.cycle_through(available_targets, self.ship.targeting_system.target)

func _available_landing_targets() -> Array[PlanetInstance]:
    var targets: Array[PlanetInstance] = []
    for node in self.get_tree().get_nodes_in_group("planets"):
        var planet_instance := node as PlanetInstance
        if planet_instance:
            targets.append(planet_instance)

    return targets

func _closest_landing_target() -> PlanetInstance:
    var nearest_planet_instance: PlanetInstance = null
    var nearest_distance := INF
    for planet_instance in self._available_landing_targets():
        var distance := planet_instance.global_transform.origin.distance_to(self.ship.global_transform.origin)
        if distance <= nearest_distance:
            nearest_planet_instance = planet_instance
            nearest_distance = distance
    
    return nearest_planet_instance

func _unhandled_key_input(event: InputEvent) -> void:
    if self.hyperspace_controller.jumping:
        return

    if event.is_action_pressed("cycle_jump_destination", true):
        self.hyperspace_controller.set_jump_destination(self._next_system_connection())
        self.get_viewport().set_input_as_handled()

    if event.is_action_pressed("cycle_target", true):
        self.ship.targeting_system.target = self._next_target()
        self.get_viewport().set_input_as_handled()

    if event.is_action_pressed("land", true):
        # Ordering matters here: _land can remove the ship from the scene, at
        # which point get_viewport() will be null.
        self.get_viewport().set_input_as_handled()
        self._land()

    if event.is_action_pressed("cycle_landing_target", true):
        var next_target: PlanetInstance = ArrayUtils.cycle_through(self._available_landing_targets(), self.landing_target)
        self.landing_target = next_target
        self.get_viewport().set_input_as_handled()

func _jump_to_hyperspace() -> void:
    if not self.hyperspace_controller.jump_destination:
        return
    
    self.landing_target = null

    # Lock controls
    self._reset_controls()
    self.hyperspace_controller.start_jump()

func _land() -> void:
    if not self.landing_target:
        self.landing_target = self._closest_landing_target()
        if not self.landing_target:
            return
    
    # Run the following checks only after a target is selected, to avoid spamming the message log.
    if self.landing_target.global_transform.origin.distance_to(self.ship.global_transform.origin) > MAX_LANDING_DISTANCE:
        self.message_log.add_message("Too far away to land.")
        return

    if self.ship.linear_velocity.length() > MAX_LANDING_VELOCITY:
        self.message_log.add_message("Moving too fast to land.")
        return

    var planet := self.landing_target.planet
    if not planet:
        self.message_log.add_message("Cannot land on this planet.")
        return

    var landing: Landing = self.landing_scene.instantiate()
    landing.planet = planet
    self.ship.add_sibling(landing)
    self.ship.get_parent().remove_child(self.ship)

    landing.show()
    landing.visibility_changed.connect(func() -> void:
        landing.add_sibling(self.ship)
        landing.queue_free()
        self._depart_from_planet())

func _depart_from_planet() -> void:
    self._reset_controls()
    self._reset_velocity()
    self.takeoff_sound.play()

func _reset_controls() -> void:
    self.ship.rigid_body_thruster.throttle = 0.0
    self.ship.rigid_body_direction.direction = Vector3.ZERO
    self.ship.rigid_body_turner.turning = 0.0

func _reset_velocity() -> void:
    self.ship.linear_velocity = Vector3.ZERO
    self.ship.angular_velocity = Vector3.ZERO

func _absolute_input_direction() -> Vector3:
    var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    return Vector3(input_direction.x, 0, input_direction.y)

func _physics_process(_delta: float) -> void:
    if self.hyperspace_controller.jumping:
        return

    if Input.is_action_pressed("jump"):
        self._jump_to_hyperspace()
        return

    if Input.is_action_pressed("fire"):
        for weapon_mount in self.ship.weapon_mounts:
            weapon_mount.fire()

    match UserPreferences.control_scheme:
        UserPreferences.ControlScheme.RELATIVE:
            if Input.is_action_pressed("thrust"):
                self.ship.rigid_body_thruster.throttle = 1.0
            else:
                self.ship.rigid_body_thruster.throttle = 0.0

            if Input.is_action_pressed("turn_backwards"):
                self.ship.rigid_body_direction.direction = -self.ship.linear_velocity.normalized()
                return

            self.ship.rigid_body_direction.direction = Vector3.ZERO
            if Input.is_action_pressed("turn_left"):
                self.ship.rigid_body_turner.turning = -1.0
            elif Input.is_action_pressed("turn_right"):
                self.ship.rigid_body_turner.turning = 1.0
            else:
                self.ship.rigid_body_turner.turning = 0.0

        UserPreferences.ControlScheme.ABSOLUTE:
            var desired_direction := self._absolute_input_direction()
            self.ship.rigid_body_direction.direction = desired_direction

            var current_direction := - self.ship.transform.basis.z
            if desired_direction != Vector3.ZERO and desired_direction.angle_to(current_direction) <= ABSOLUTE_DIRECTION_TOLERANCE_RAD:
                self.ship.rigid_body_thruster.throttle = desired_direction.length()
            else:
                self.ship.rigid_body_thruster.throttle = 0.0
