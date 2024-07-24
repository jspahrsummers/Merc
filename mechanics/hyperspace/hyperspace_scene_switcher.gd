extends Node3D
class_name HyperspaceSceneSwitcher

## Coordinates loading new scenes for the player's hyperspace jumps.
##
## This node must contain exactly one [StarSystemInstance] child at all times.

## The player's [HyperdriveSystem].
@export var hyperdrive_system: HyperdriveSystem

## The game [Calendar] to update when jumping, to represent time passing.
@export var calendar: Calendar

## Fires when the hyperspace destination has been loaded and added to the current scene, but before the full visual effect has finished.
signal jump_destination_loaded(new_system_instance: StarSystemInstance)

## Used to keep systems around in memory, so their state is remembered.
var _loaded_system_nodes: Dictionary = {}

func _ready() -> void:
    var current_system_instance: StarSystemInstance = self.get_child(0)
    var current_system := current_system_instance.star_system
    self._loaded_system_nodes[current_system.name] = current_system_instance

func start_jump() -> bool:
    assert(not self.hyperdrive_system.jumping, "Jump already in progress")

    if not self.hyperdrive_system.hyperdrive.consume_for_jump():
        return false

    if not self._loaded_system_nodes.has(self.hyperdrive_system.jump_destination.name):
        ResourceLoader.load_threaded_request(self.hyperdrive_system.jump_destination.scene_path)

    self.hyperdrive_system.jumping = true
    return true

func load_jump_destination() -> void:
    assert(self.hyperdrive_system.jumping, "Expected a jump to be in progress")

    var destination := self.hyperdrive_system.jump_destination
    assert(destination, "Expected to have a jump destination")

    var player_ship := self.hyperdrive_system.ship
    var previous_system_instance := StarSystemInstance.star_system_instance_for_node(player_ship)
    previous_system_instance.remove_child(player_ship)
    self.remove_child(previous_system_instance)

    var star_system_instance: StarSystemInstance = self._loaded_system_nodes.get(destination.name)
    if star_system_instance == null:
        print("Instantiating node for ", destination)
        var new_scene := ResourceLoader.load_threaded_get(destination.scene_path) as PackedScene
        star_system_instance = new_scene.instantiate()

        self._loaded_system_nodes[destination.name] = star_system_instance
    else:
        print("Restoring node for ", destination)

    star_system_instance.add_child(player_ship)
    self.add_child(star_system_instance)

    calendar.increment_kilocycle()

    self.hyperdrive_system.jump_destination = null
    self.jump_destination_loaded.emit(star_system_instance)

func finish_jump() -> void:
    assert(self.hyperdrive_system.jumping, "No jump in progress")
    self.hyperdrive_system.jumping = false
