extends Node
class_name Player

## The player.

@export var hyperspace_controller: HyperspaceController
@export var ship: Ship

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

## When using the "absolute" control scheme, this is the tolerance (in radians) for being slightly off-rotated while enabling thrusters.
const ABSOLUTE_DIRECTION_TOLERANCE_RAD = 0.1745

# TODO: Put this somewhere better (per ship?)
const HYPERSPACE_ARRIVAL_RADIUS = 8.0

func _ready() -> void:
    var turner: RigidBodyTurner = RigidBodyTurner.new()
    turner.spin_thruster = self.ship.rigid_body_direction.spin_thruster
    turner.battery = self.ship.rigid_body_direction.battery

    self.ship.add_child(turner)
    self.ship.rigid_body_turner = turner

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

func _on_target_changed() -> void:
    self.target_changed.emit(self, self.ship.targeting_system.target)

# func set_target(targeted_ship: Ship) -> void:
#     if self.target != null:
#         self.target.set_targeted_by_player(false)
    
#     super(targeted_ship)

#     if self.target != null:
#         self.target.set_targeted_by_player(true)

func _on_jump_destination_loaded(_system: StarSystem) -> void:
    self.ship.linear_velocity = Vector3.ZERO
    self.ship.angular_velocity = Vector3.ZERO
    self.ship.position = MathUtils.random_unit_vector() * HYPERSPACE_ARRIVAL_RADIUS
    self.ship.targeting_system.target = null

## Cycles through systems connected to this one, for picking a hyperspace jump destination.
func _next_system_connection() -> StarSystem:
    var connections := self.hyperspace_controller.current_system.connections
    if connections.size() == 0:
        return null

    if self.hyperspace_controller.jump_destination == null:
        return self.hyperspace_controller.galaxy.get_system(connections[0])

    var index := connections.find(self.hyperspace_controller.jump_destination.name)
    assert(index >= 0, "Cannot find jump destination in system connections")

    return self.hyperspace_controller.galaxy.get_system(connections[index + 1]) if index + 1 < connections.size() else null

## Cycles through ships in the current system, for picking a target.
func _next_ship_target() -> Ship:
    var ships := get_tree().get_nodes_in_group("ships")
    ships.erase(self)
    ships = ships.filter(func(s: Ship) -> bool: return s.is_visible_in_tree())
    if ships.size() == 0:
        return null
    
    var target := self.ship.targeting_system.target
    if target == null:
        return ships[0]
    
    var index := ships.find(target)
    assert(index >= 0, "Cannot find targeted ship")

    return ships[index + 1] if index + 1 < ships.size() else null

func _unhandled_input(event: InputEvent) -> void:
    if self.hyperspace_controller.jumping:
        return

    if event.is_action_pressed("cycle_jump_destination"):
        self.hyperspace_controller.set_jump_destination(_next_system_connection())
        self.get_viewport().set_input_as_handled()

    if event.is_action_pressed("cycle_target"):
        self.ship.targeting_system.target = _next_ship_target().combat_object
        self.get_viewport().set_input_as_handled()
    
    if UserPreferences.control_scheme == UserPreferences.ControlScheme.RELATIVE:
        if event.is_action_pressed("thrust"):
            self.ship.rigid_body_thruster.throttle = 1.0
        elif event.is_action_released("thrust"):
            self.ship.rigid_body_thruster.throttle = 0.0

    if event.is_action_pressed("fire"):
        for weapon_mount in self.ship.weapon_mounts:
            weapon_mount.fire()

    if event.is_action_pressed("jump") and self.hyperspace_controller.jump_destination != null:
        self.hyperspace_controller.start_jump()

func _absolute_input_direction() -> Vector3:
    var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    return Vector3(input_direction.x, 0, input_direction.y)

func _physics_process(_delta: float) -> void:
    if self.hyperspace_controller.jumping:
        return

    match UserPreferences.control_scheme:
        UserPreferences.ControlScheme.RELATIVE:
            if Input.is_action_pressed("turn_backwards"):
                self.ship.rigid_body_direction.direction = -self.ship.linear_velocity.normalized()
                return
            else:
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
