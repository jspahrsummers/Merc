extends Node3D
class_name HyperdriveSystem

## Controls a ship's [Hyperdrive] and jumps to hyperspace.
##
## [b]This script expects the parent node to be a [Ship].[/b]

## The hyperdrive to use.
var hyperdrive: Hyperdrive

## Whether a jump is currently being performed.
##
## At the moment, changing this has no effect besides firing [signal jumping_changed].
var jumping: bool = false:
    set(value):
        assert(not value or self._jump_path, "If jumping, a jump path should already be set")

        if jumping == value:
            return
        
        jumping = value
        self.jumping_changed.emit(self)

## The [Ship] this hyperdrive system is attached to.
@onready var ship := get_parent() as Ship

## The planned multi-step hyperspace path.
var _jump_path: Array[StarSystem] = []

## Fires when [member jumping] changes.
signal jumping_changed(hyperdrive_system: HyperdriveSystem)

## Fires when the [member jump_path] changes.
signal jump_path_changed(hyperdrive_system: HyperdriveSystem)

## The current system the ship is located in.
func current_system() -> StarSystem:
    var instance := StarSystemInstance.star_system_instance_for_node(self)
    if not instance:
        push_error("HyperdriveSystem is not part of a StarSystemInstance")
        return null
    
    return instance.star_system

## Returns the planned jump path.
func get_jump_path() -> Array[StarSystem]:
    return self._jump_path.duplicate()

## Returns the immediately next jump destination.
func get_jump_destination() -> StarSystem:
    return self._jump_path[0] if self._jump_path else null

## Sets the planned jump path.
func set_jump_path(path: Array[StarSystem]) -> void:
    if path == self._jump_path:
        return
    
    self._jump_path = path.duplicate()
    self.jump_path_changed.emit(self)

## Adds a system to the end of the jump path.
func add_to_jump_path(system: StarSystem) -> void:
    self._jump_path.append(system)
    self.jump_path_changed.emit(self)

## Clears the current jump path.
func clear_jump_path() -> void:
    self._jump_path.clear()
    self.jump_path_changed.emit(self)

## Updates the jump path after a successful jump.
func shift_jump_path() -> void:
    assert(self._jump_path, "Jump path must not be empty")
    self._jump_path.pop_front()
    self.jump_path_changed.emit(self)
