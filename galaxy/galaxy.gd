extends Resource
class_name Galaxy

## Represents a galaxy of star systems.
##
## Only one galaxy is playable at any given time, but testing or add-on content may want to swap out the default galaxy.

## A list of all systems in the galaxy.
@export var systems: Array[StarSystem]

## Looks up a system by name.
func get_system(name: StringName) -> StarSystem:
    for system in systems:
        if system.name == name:
            return system
    
    return null
