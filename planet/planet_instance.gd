extends Node3D
class_name PlanetInstance

## Defines properties and facilities for this planet.
##
## If not set, the planet is assumed uninhabitable and cannot be landed upon.
@export var planet: Planet

## An overlay to show if the player is targeting this planet.
@export var target_overlay: Node3D

## Whether this planet is being targeted by the player.
var targeted_by_player: bool:
    set(value):
        targeted_by_player = value
        self.target_overlay.visible = targeted_by_player

## Missions available to pick up from this planet.
##
## This is reset only when the player leaves the star system.
var _available_missions: Array[Mission] = []

## Creates or returns the missions currently available to pick up from this planet.
func get_available_missions() -> Array[Mission]:
    if not self._available_missions:
        for i in randi_range(3, 5):
            var mission := Mission.create_random_delivery_mission(self.planet)
            self._available_missions.push_back(mission)

    return self._available_missions

func _enter_tree() -> void:
    self.targeted_by_player = false

func _exit_tree() -> void:
    self._available_missions.clear()

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
    if event is InputEventMouseButton:
        InputEventBroadcaster.broadcast(self, event)

## See [SaveGame].
func save_to_dict() -> Dictionary:
    var result := {}
    result["available_missions"] = self._available_missions.map(func(mission: Mission) -> Dictionary:
        return mission.save_to_dict()
    )
    return result

## See [SaveGame].
func load_from_dict(dict: Dictionary) -> void:
    var mission_dicts: Array = dict["available_missions"]
    var loaded_missions := mission_dicts.map(func(mission_dict: Dictionary) -> Mission:
        var mission: Mission = Mission.new()
        mission.load_from_dict(mission_dict)
        return mission
    )

    self._available_missions.assign(loaded_missions)
