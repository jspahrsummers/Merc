extends Ship

## The player's ship.

@export var hyperspace_controller: HyperspaceController

## When using the "absolute" control scheme, this is the tolerance (in radians) for being slightly off-rotated while enabling thrusters.
const ABSOLUTE_DIRECTION_TOLERANCE_RAD = 0.1745

func set_target(targeted_ship: Ship) -> void:
    if self.target != null:
        self.target.set_targeted_by_player(false)
    
    super(targeted_ship)

    if self.target != null:
        self.target.set_targeted_by_player(true)

func _on_jump_destination_loaded(_system: StarSystem) -> void:
    self.linear_velocity = Vector3.ZERO
    self.angular_velocity = Vector3.ZERO
    self.position = MathUtils.random_unit_vector() * self.ship_def.hyperspace_arrival_radius
    self.set_target(null)

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
    ships = ships.filter(func(ship: Ship) -> bool: return ship.is_visible_in_tree())
    if ships.size() == 0:
        return null
    
    if self.target == null:
        return ships[0]
    
    var index := ships.find(self.target)
    assert(index >= 0, "Cannot find targeted ship")

    return ships[index + 1] if index + 1 < ships.size() else null

func _unhandled_input(event: InputEvent) -> void:
    if self.hyperspace_controller.jumping:
        return

    if event.is_action_pressed("cycle_jump_destination"):
        self.hyperspace_controller.set_jump_destination(_next_system_connection())
        self.get_viewport().set_input_as_handled()

    if event.is_action_pressed("cycle_target"):
        self.set_target(_next_ship_target())
        self.get_viewport().set_input_as_handled()

func _absolute_input_direction() -> Vector3:
    var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    return Vector3(input_direction.x, 0, input_direction.y)

func _physics_process(delta: float) -> void:
    super(delta)

    if self.hyperspace_controller.jumping:
        return

    match UserPreferences.control_scheme:
        UserPreferences.ControlScheme.RELATIVE:
            if Input.is_action_pressed("thrust"):
                self.thrust_step(1.0, delta)
            else:
                self.thrust_stopped()
        
        UserPreferences.ControlScheme.ABSOLUTE:
            var desired_direction := self._absolute_input_direction()
            var current_direction := - self.transform.basis.z
            if desired_direction != Vector3.ZERO and desired_direction.angle_to(current_direction) <= ABSOLUTE_DIRECTION_TOLERANCE_RAD:
                self.thrust_step(desired_direction.length(), delta)
            else:
                self.thrust_stopped()

    if Input.is_action_pressed("fire"):
        self.fire()
    
    if Input.is_action_pressed("jump") and self.hyperspace_controller.jump_destination != null:
        self.hyperspace_controller.start_jump()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    if self.hyperspace_controller.jumping:
        return

    match UserPreferences.control_scheme:
        UserPreferences.ControlScheme.RELATIVE:
            var turning_left := Input.is_action_pressed("turn_left")
            var turning_right := Input.is_action_pressed("turn_right")
            var turning_backwards := Input.is_action_pressed("turn_backwards")
            if not turning_left and not turning_right and not turning_backwards:
                return
            
            if not self.consume_turning_energy(state.get_step()):
                return

            if turning_left:
                state.angular_velocity = Vector3.ZERO
                state.transform.basis = state.transform.basis.rotated(Vector3.DOWN, -self.ship_def.torque * state.get_step())
            if turning_right:
                state.angular_velocity = Vector3.ZERO
                state.transform.basis = state.transform.basis.rotated(Vector3.DOWN, self.ship_def.torque * state.get_step())
            if turning_backwards:
                var desired_basis := Basis.looking_at( - self.linear_velocity.normalized())

                state.angular_velocity = Vector3.ZERO
                state.transform.basis = state.transform.basis.slerp(desired_basis, self.ship_def.torque * state.get_step())

        UserPreferences.ControlScheme.ABSOLUTE:
            var desired_direction := self._absolute_input_direction()
            if desired_direction == Vector3.ZERO:
                return

            if not self.consume_turning_energy(state.get_step()):
                return

            var desired_basis := Basis.looking_at(desired_direction)
            state.transform.basis = state.transform.basis.slerp(desired_basis, self.ship_def.torque * state.get_step())
