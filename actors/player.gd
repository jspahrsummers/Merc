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
@export var mission_controller: MissionController
@export var hero_roster: HeroRoster
@export var main_camera: MainCamera

@onready var ship := get_parent() as Ship

## Fires when the ship's hull changes (e.g., due to damage).
signal hull_changed(player: Player, hull: Hull)

## Fires when the ship's shield changes (e.g., due to damage).
signal shield_changed(player: Player, shield: Shield)

## Fires when the ship's power level changes.
signal power_changed(player: Player, battery: Battery)

## Fires when the ship's heat level changes.
signal heat_changed(player: Player, heat_sink: HeatSink)

## Fires when the player's ship is destroyed.
signal ship_destroyed(player: Player)

## Fires when the player changes their target.
signal target_changed(player: Player, target: CombatObject)

## Fires when the player changes their landing target.
signal landing_target_changed(player: Player, target: Celestial)

## Fires when the player lands on a port.
signal landed(player: Player, port: Port)

## Fires when the ship's hyperdrive changes.
signal hyperdrive_changed(player: Player, hyperdrive: Hyperdrive)

## Fires when the ship's cargo hold changes.
signal cargo_hold_changed(player: Player, cargo_hold: CargoHold)

## Fires when the ship's passenger quarters changes.
signal passenger_quarters_changed(player: Player, passenger_quarters: PassengerQuarters)

## The current target for landing, if any.
var landing_target: Celestial = null:
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

## The AINavigation object for the CLICK_TO_MOVE control scheme.
@export var ai_navigation: AINavigation

## When using the "absolute" control scheme, this is the tolerance (in radians) for being slightly off-rotated while enabling thrusters.
const ABSOLUTE_DIRECTION_TOLERANCE_RAD = 0.1745

## The approximate number of days that should pass with each landing at a port.
const PORT_LANDING_APPROXIMATE_DAYS = 1

# TODO: Put this somewhere better (per ship?)
const HYPERSPACE_ARRIVAL_RADIUS = 8.0
const MAX_LANDING_DISTANCE = 2.0
const MAX_LANDING_VELOCITY = 4.0

## The deadzone radius for the mouse joystick control scheme
const MOUSE_JOYSTICK_DEADZONE = 100.0

## The maximum radius for the mouse joystick control scheme
const MOUSE_JOYSTICK_MAX_RADIUS = 400.0

var _mouse_position: Vector2 = Vector2.INF
var _mouse_joystick_center: Vector2 = Vector2.INF

func _ready() -> void:
    if not self.save_node_path_override:
        self.save_node_path_override = self.get_path()
        self.ship.save_node_path_override = self.ship.get_path()
        self.mission_controller.save_node_path_override = self.mission_controller.get_path()

    self._rigid_body_turner = RigidBodyTurner.new()
    self._rigid_body_turner.spin_thruster = self.ship.rigid_body_direction.spin_thruster
    self._rigid_body_turner.battery = self.ship.battery
    self.ship.add_child.call_deferred(self._rigid_body_turner)
    self.ship.radar_object.iff = RadarObject.IFF.SELF
    self.ship.targeting_system.is_player = true

    self.ship.hull.changed.connect(_on_hull_changed)
    self.ship.hull.hull_destroyed.connect(_on_hull_destroyed)
    self.ship.battery.changed.connect(_on_power_changed)
    self.ship.heat_sink.changed.connect(_on_heat_changed)
    self.ship.targeting_system.target_changed.connect(_on_target_changed)

    InputEventBroadcaster.input_event.connect(_on_broadcasted_input_event)

    # Initial notifications so the UI can update.
    self._on_hull_changed()
    self._on_power_changed()
    self._on_heat_changed()

    if self.ship.shield:
        self.ship.shield.changed.connect(_on_shield_changed)
        self._on_shield_changed()

    if self.ship.hyperdrive:
        self.ship.hyperdrive.changed.connect(_on_hyperdrive_changed)
        self._on_hyperdrive_changed()
    
    if self.ship.cargo_hold:
        self.ship.cargo_hold.changed.connect(_on_cargo_hold_changed)
        self._on_cargo_hold_changed()
    
    if self.ship.passenger_quarters:
        self.ship.passenger_quarters.changed.connect(_on_passenger_quarters_changed)
        self._on_passenger_quarters_changed()

    self.mission_controller.calendar = self.calendar
    self.mission_controller.cargo_hold = self.ship.cargo_hold
    self.mission_controller.passenger_quarters = self.ship.passenger_quarters
    self.mission_controller.bank_account = self.bank_account

func _on_hull_changed() -> void:
    self.hull_changed.emit(self, self.ship.hull)

func _on_shield_changed() -> void:
    self.shield_changed.emit(self, self.ship.shield)

func _on_power_changed() -> void:
    self.power_changed.emit(self, self.ship.battery)

func _on_heat_changed() -> void:
    self.heat_changed.emit(self, self.ship.heat_sink)

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

func _on_passenger_quarters_changed() -> void:
    self.passenger_quarters_changed.emit(self, self.ship.passenger_quarters)

func _on_cargo_hold_changed() -> void:
    self.cargo_hold_changed.emit(self, self.ship.cargo_hold)

func _next_system_connection() -> StarSystem:
    var current_destination_name: Variant = null
    if self.ship.hyperdrive_system.get_jump_destination():
        current_destination_name = self.ship.hyperdrive_system.get_jump_destination().name

    var current_system := self.ship.hyperdrive_system.current_system()
    var galaxy: Galaxy = current_system.galaxy.get_ref()
    var next_destination_name: Variant = CollectionUtils.cycle_through(current_system.connections, current_destination_name)
    return galaxy.get_system(next_destination_name as StringName) if next_destination_name else null

func _next_target() -> CombatObject:
    var available_targets := self.ship.targeting_system.get_available_targets()
    available_targets.erase(self.ship.combat_object)
    return CollectionUtils.cycle_through(available_targets, self.ship.targeting_system.target)

func _available_landing_targets() -> Array[Celestial]:
    var targets: Array[Celestial] = []
    for node in self.get_tree().get_nodes_in_group("celestials"):
        var celestial := node as Celestial
        if celestial:
            targets.append(celestial)

    return targets

func _closest_landing_target() -> Celestial:
    var nearest_celestial: Celestial = null
    var nearest_distance := INF
    for celestial in self._available_landing_targets():
        var distance := celestial.global_transform.origin.distance_to(self.ship.global_transform.origin)
        if distance <= nearest_distance:
            nearest_celestial = celestial
            nearest_distance = distance

    return nearest_celestial

func _unhandled_input(event: InputEvent) -> void:
    if self.ship.controls_disabled():
        return
    
    var motion_event := event as InputEventMouseMotion
    if motion_event:
        self._mouse_joystick_center = self.get_viewport().get_visible_rect().size / 2
        self._mouse_position = motion_event.global_position
        self.get_viewport().set_input_as_handled()

    if UserPreferences.control_scheme == UserPreferences.ControlScheme.CLICK_TO_MOVE:
        var mouse_button_event := event as InputEventMouseButton
        if mouse_button_event and mouse_button_event.pressed and mouse_button_event.button_index == MOUSE_BUTTON_LEFT and not self.ai_navigation.navigating:
            var destination := self.main_camera.project_position_with_zoom(mouse_button_event.position)
            self.ai_navigation.set_destination(destination)
            self.ai_navigation.navigating = true

    if event.is_action_pressed("cycle_jump_destination", true):
        var next_system := self._next_system_connection()
        if next_system:
            self.ship.hyperdrive_system.set_jump_path([next_system])
        else:
            self.ship.hyperdrive_system.clear_jump_path()

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
        var next_target: Celestial = CollectionUtils.cycle_through(self._available_landing_targets(), self.landing_target)
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
        self.ship.targeting_system.target = combat_object if combat_object != self.ship.combat_object else null
        return

    var celestial := receiver as Celestial
    if celestial:
        self.landing_target = celestial
        return

func _jump_to_hyperspace() -> void:
    if not self.ship.hyperdrive_system.get_jump_destination():
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

    var port := self.landing_target.port
    if not port:
        self.message_log.add_message("Cannot land here.")
        return

    var landing: Landing = self.landing_scene.instantiate()
    landing.player = self
    landing.celestial = self.landing_target
    landing.star_system = self.ship.hyperdrive_system.current_system()
    self.ship.add_sibling(landing)
    self.ship.get_parent().remove_child(self.ship)

    landing.show()
    landing.visibility_changed.connect(func() -> void:
        landing.add_sibling(self.ship)
        landing.queue_free()
        self._depart_from_port(port))

    self.landed.emit(self, port)

func _depart_from_port(port: Port) -> void:
    self.message_log.clear()

    self.calendar.pass_approximate_days(PORT_LANDING_APPROXIMATE_DAYS)

    if self.ship.battery:
        self.ship.battery.power = self.ship.battery.max_power
    if self.ship.shield:
        self.ship.shield.integrity = self.ship.shield.max_integrity
    self.ship.hull.integrity = self.ship.hull.max_integrity

    self._reset_controls()
    self._reset_velocity()
    self.takeoff_sound.play()
    self.message_log.add_message("Departing from %s at %s." % [port.name, self.calendar.get_gst()], MessageLog.LONG_MESSAGE_LIFETIME, false)

func _reset_controls() -> void:
    self.ship.rigid_body_thruster.throttle = 0.0
    self.ship.rigid_body_direction.direction = Vector3.ZERO
    self._rigid_body_turner.turning = 0.0
    if self.ai_navigation:
        self.ai_navigation.navigating = false

func _reset_velocity() -> void:
    self.ship.linear_velocity = Vector3.ZERO
    self.ship.angular_velocity = Vector3.ZERO

func _absolute_input_direction() -> Vector3:
    var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    return Vector3(input_direction.x, 0, input_direction.y)

func _mouse_joystick_input() -> Vector2:
    if not self._mouse_joystick_center.is_finite() or not self._mouse_position.is_finite():
        return Vector2.INF

    var offset := self._mouse_position - self._mouse_joystick_center
    var distance := offset.length()
    
    if distance < MOUSE_JOYSTICK_DEADZONE:
        return Vector2.ZERO
    
    var normalized_distance := (distance - MOUSE_JOYSTICK_DEADZONE) / (MOUSE_JOYSTICK_MAX_RADIUS - MOUSE_JOYSTICK_DEADZONE)
    normalized_distance = clampf(normalized_distance, 0, 1)
    
    return offset.normalized() * normalized_distance

func _physics_process(_delta: float) -> void:
    if self.ship.controls_disabled():
        self.ship.set_firing(false)
        self.ship.rigid_body_thruster.throttle = 0.0
        self.ship.rigid_body_direction.direction = Vector3.ZERO
        self._rigid_body_turner.turning = 0.0
        return

    if Input.is_action_pressed("jump"):
        self._jump_to_hyperspace()
        return

    self.ship.set_firing(Input.is_action_pressed("fire"))

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

        UserPreferences.ControlScheme.MOUSE_JOYSTICK:
            var input := self._mouse_joystick_input()
            if input.is_finite():
                var desired_direction := Vector3(input.x, 0, input.y)
                
                self.ship.rigid_body_direction.direction = desired_direction
                self.ship.rigid_body_thruster.throttle = desired_direction.length()

        UserPreferences.ControlScheme.CLICK_TO_MOVE:
            # The AINavigation component handles the movement in this mode
            pass

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
