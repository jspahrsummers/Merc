extends Resource
class_name Galaxy

## Represents a galaxy of star systems.
##
## Only one galaxy is playable at any given time, but testing or add-on content may want to swap out the default galaxy.

## A list of all systems in the galaxy.
@export var systems: Array[StarSystem]

## A list of all planets in the galaxy.
var planets: Array = []

func _init() -> void:
    self._connect_backref.call_deferred()

    for system in self.systems:
        self.planets.append_array(system.planets)

func _connect_backref() -> void:
    for system in self.systems:
        system.galaxy = weakref(self)

## Looks up a system by name.
func get_system(name: StringName) -> StarSystem:
    for system in systems:
        if system.name == name:
            return system

    return null
