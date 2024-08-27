extends Node3D
class_name Celestial

## Represents a celestial object—like a planet, moon, asteroid, or a space station (but [i]not[/i] a star)—that the player can target and possibly land on.

## Defines properties and facilities for this celestial.
##
## If not set, the celestial is assumed uninhabitable and cannot be landed upon.
@export var port: Port

## An overlay to show if the player is targeting this celestial.
@export var target_overlay: Node3D

## Whether this celestial is being targeted by the player.
var targeted_by_player: bool:
    set(value):
        targeted_by_player = value
        self.target_overlay.visible = targeted_by_player

## Missions available to pick up from this celestial.
##
## This is reset only when the player leaves the star system.
var _available_missions: Array[Mission] = []

## Creates or returns the missions currently available to pick up from this celestial.
func get_available_missions(calendar: Calendar, hero_roster: HeroRoster) -> Array[Mission]:
    if not self._available_missions:
        var desired_count := randi_range(3, 5)
        while self._available_missions.size() < desired_count:
            var mission := Mission.create_random_mission(self.port, calendar, hero_roster)
            if mission and Mission.filter_incompatible_missions(self._available_missions, [mission]):
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
