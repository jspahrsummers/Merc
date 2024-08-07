extends Node3D
class_name Player

## The player.
##
## [b]This script expects the parent node to be a [Ship].[/b]

@export var hyperspace_scene_switcher: HyperspaceSceneSwitcher
@export var message_log: MessageLog
@export var landing_scene: PackedScene
@export var takeoff_sound: AudioStreamPlayer
@export var bank_account: BankAccount
@export var calendar: Calendar

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

## Fires when the player lands on a planet.
signal landed(player: Player, planet: Planet)

## Fires when the ship's hyperdrive changes.
signal hyperdrive_changed(player: Player, hyperdrive: Hyperdrive)

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

## Used to save and restore the player object correctly across launches.
var save_node_path_override: NodePath

## Created to turn the [Ship] when using the relative control scheme.
var _rigid_body_turner: RigidBodyTurner

## When using the "absolute" control scheme, this is the tolerance (in radians) for being slightly off-rotated while enabling thrusters.
const ABSOLUTE_DIRECTION_TOLERANCE_RAD = 0.1745

## The approximate number of days that should pass with each planetary landing.
const PLANET_LANDING_APPROXIMATE_DAYS = 1

# TODO: Put this somewhere better (per ship?)
const HYPERSPACE_ARRIVAL_RADIUS = 8.0
const MAX_LANDING_DISTANCE = 2.0
const MAX_LANDING_VELOCITY = 4.0

func _ready() -> void:
    if not self.save_node_path_override:
        self.save_node_path_override = self.get_path()
        self.ship.save_node_path_override = self.ship.get_path()

    self._rigid_body_turner = RigidBodyTurner.new()
    self._rigid_body_turner.spin_thruster = self.ship.rigid_body_direction.spin_thruster
    self._rigid_body_turner.battery = self.ship.battery
    self.ship.add_child.call_deferred(self._rigid_body_turner)
    self.ship.radar_object.iff = RadarObject.IFF.SELF
    self.ship.targeting_system.is_player = true

    self.ship.hull.changed.connect(_on_hull_changed)
    self.ship.hull.hull_destroyed.connect(_on_hull_destroyed)
    self.ship.battery.changed.connect(_on_power_changed)
    self.ship.targeting_system.target_changed.connect(_on_target_changed)

    InputEventBroadcaster.input_event.connect(_on_broadcasted_input_event)

    # Initial notifications so the UI can update.
    self._on_hull_changed()
    self._on_power_changed()

    if self.ship.shield:
        self.ship.shield.changed.connect(_on_shield_changed)
        self._on_shield_changed()

    if self.ship.hyperdrive:
        self._on_hyperdrive_changed()
        self.ship.hyperdrive.changed.connect(_on_hyperdrive_changed)

func _on_hull_changed() -> void:
    self.hull_changed.emit(self, self.ship.hull)

func _on_shield_changed() -> void:
    self.shield_changed.emit(self, self.ship.shield)

func _on_power_changed() -> void:
    self.power_changed.emit(self, self.ship.battery)

func _on_hull_destroyed(hull: Hull) -> void:
    assert(hull == self.ship.hull, "Received hull_destroyed signal from incorrect hull")
    self.ship_destroyed.emit(self)

func _on_target_changed(targeting_system: TargetingSystem) -> void:
    self.target_changed.emit(self, targeting_system.target)

func _on_jump_destination_loaded(_new_system_instance: StarSystemInstance) -> void:
    if not self.ship.hyperdrive_system.jumping:
        # A bit of a hack to ignore this notification when reloading from a saved game, while allowing it to propagate to other nodes (e.g., UI).
        return

    self._reset_velocity()
    self.ship.position = MathUtils.random_unit_vector() * HYPERSPACE_ARRIVAL_RADIUS
    self.ship.targeting_system.target = null

func _on_hyperdrive_changed() -> void:
    self.hyperdrive_changed.emit(self, self.ship.hyperdrive)

func _next_system_connection() -> StarSystem:
    var current_destination_name: Variant = null
    if self.ship.hyperdrive_system.jump_destination:
        current_destination_name = self.ship.hyperdrive_system.jump_destination.name

    var current_system := self.ship.hyperdrive_system.current_system()
    var galaxy: Galaxy = current_system.galaxy.get_ref()
    var next_destination_name: Variant = ArrayUtils.cycle_through(current_system.connections, current_destination_name)
    return galaxy.get_system(next_destination_name as StringName) if next_destination_name else null

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
    if self.ship.hyperdrive_system.jumping:
        return

    if event.is_action_pressed("cycle_jump_destination", true):
        self.ship.hyperdrive_system.jump_destination = self._next_system_connection()
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

func _on_broadcasted_input_event(receiver: Node, event: InputEvent) -> void:
    var mouse_button_event := event as InputEventMouseButton
    if not mouse_button_event:
        return
    
    if mouse_button_event.button_index != MOUSE_BUTTON_LEFT or not mouse_button_event.pressed:
        return
    
    var combat_object := receiver as CombatObject
    if combat_object:
        self.ship.targeting_system.target = combat_object
        return
    
    var planet_instance := receiver as PlanetInstance
    if planet_instance:
        self.landing_target = planet_instance
        return

func _jump_to_hyperspace() -> void:
    if not self.ship.hyperdrive_system.jump_destination:
        return
    
    if not self.hyperspace_scene_switcher.start_jump():
        return

    self.landing_target = null

    # Lock controls
    self._reset_controls()

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
    landing.player = self
    landing.planet = planet
    landing.star_system = self.ship.hyperdrive_system.current_system()
    self.ship.add_sibling(landing)
    self.ship.get_parent().remove_child(self.ship)

    landing.show()
    landing.visibility_changed.connect(func() -> void:
        landing.add_sibling(self.ship)
        landing.queue_free()
        self._depart_from_planet())
    
    self.landed.emit(self, planet)

func _depart_from_planet() -> void:
    self.calendar.pass_approximate_days(PLANET_LANDING_APPROXIMATE_DAYS)
    self._reset_controls()
    self._reset_velocity()
    self.takeoff_sound.play()

func _reset_controls() -> void:
    self.ship.rigid_body_thruster.throttle = 0.0
    self.ship.rigid_body_direction.direction = Vector3.ZERO
    self._rigid_body_turner.turning = 0.0

func _reset_velocity() -> void:
    self.ship.linear_velocity = Vector3.ZERO
    self.ship.angular_velocity = Vector3.ZERO

func _absolute_input_direction() -> Vector3:
    var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    return Vector3(input_direction.x, 0, input_direction.y)

func _physics_process(_delta: float) -> void:
    if not self.ship.hyperdrive_system or self.ship.hyperdrive_system.jumping:
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
                self._rigid_body_turner.turning = -1.0
            elif Input.is_action_pressed("turn_right"):
                self._rigid_body_turner.turning = 1.0
            else:
                self._rigid_body_turner.turning = 0.0

        UserPreferences.ControlScheme.ABSOLUTE:
            var desired_direction := self._absolute_input_direction()
            self.ship.rigid_body_direction.direction = desired_direction

            var current_direction := -self.ship.transform.basis.z
            if desired_direction != Vector3.ZERO and desired_direction.angle_to(current_direction) <= ABSOLUTE_DIRECTION_TOLERANCE_RAD:
                self.ship.rigid_body_thruster.throttle = desired_direction.length()
            else:
                self.ship.rigid_body_thruster.throttle = 0.0

## See [SaveGame].
func save_to_dict() -> Dictionary:
    var result := {}
    SaveGame.save_resource_property_into_dict(self, result, "bank_account")
    SaveGame.save_resource_property_into_dict(self, result, "calendar")
    return result

## See [SaveGame].
func load_from_dict(dict: Dictionary) -> void:
    SaveGame.load_resource_property_from_dict(self, dict, "bank_account")
    SaveGame.load_resource_property_from_dict(self, dict, "calendar")
