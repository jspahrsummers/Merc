extends Resource
class_name Galaxy

## Represents a galaxy of star systems.
##
## Only one galaxy is playable at any given time, but testing or add-on content may want to swap out the default galaxy.

## Dynamically loaded systems in the galaxy.
var systems: Array[StarSystem] = []

## A list of all ports in the galaxy.
var ports: Array = []

## The directory where all star system resources are stored.
const _STAR_SYSTEMS_DIRECTORY = "res://galaxy/star_system/star_systems"

func _init() -> void:
    var files := DirAccess.get_files_at(_STAR_SYSTEMS_DIRECTORY)
    for file in files:
        if not file.ends_with(".tres"):
            continue

        var system: StarSystem = load("%s/%s" % [_STAR_SYSTEMS_DIRECTORY, file])
        system.galaxy = weakref(self)
        self.systems.append(system)
        self.ports.append_array(system.ports)

## Looks up a system by name.
func get_system(name: StringName) -> StarSystem:
    for system in self.systems:
        if system.name == name:
            return system

    return null
