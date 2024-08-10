extends Resource
class_name Galaxy

## Represents a galaxy of star systems.
##
## Only one galaxy is playable at any given time, but testing or add-on content may want to swap out the default galaxy.

## A list of all systems in the galaxy.
@export var systems: Array[StarSystem]

## A dictionary of [Planet] keys to their containing [StarSystem] values.
var planets_with_systems: Dictionary = {}

func _init() -> void:
    self._connect_backref.call_deferred()

    for system in systems:
        for planet in system.planets:
            assert(planet not in planets_with_systems, "Planet %s should not exist in multiple systems" % planet)
            planets_with_systems[planet] = system

func _connect_backref() -> void:
    for system in self.systems:
        system.galaxy = weakref(self)

## Looks up a system by name.
func get_system(name: StringName) -> StarSystem:
    for system in systems:
        if system.name == name:
            return system

    return null
