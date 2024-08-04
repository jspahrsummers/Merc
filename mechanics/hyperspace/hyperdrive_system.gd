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
        assert(not value or self.jump_destination != null, "If jumping, a jump destination should already be set")

        if jumping == value:
            return
        
        jumping = value
        self.jumping_changed.emit(self)

## The current jump destination, if one is selected.
var jump_destination: StarSystem = null:
    set(value):
        assert(value != self.current_system(), "Jump destination should not be the same as the current system")
        assert(value == null or value.name in self.current_system().connections, "Jump destination should be connected to the current system")

        if jump_destination == value:
            return
        
        jump_destination = value
        self.jump_destination_changed.emit(self)

## The [Ship] this hyperdrive system is attached to.
@onready var ship := get_parent() as Ship

## Fires when [member jumping] changes.
signal jumping_changed(hyperdrive_system: HyperdriveSystem)

## Fires when [member jump_destination] changes.
signal jump_destination_changed(hyperdrive_system: HyperdriveSystem)

## The current system the ship is located in.
func current_system() -> StarSystem:
    var instance := StarSystemInstance.star_system_instance_for_node(self)
    if not instance:
        push_error("HyperdriveSystem is not part of a StarSystemInstance")
        return null
    
    return instance.star_system
