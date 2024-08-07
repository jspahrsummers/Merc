extends Node3D

## Manages mission status for the player.

@export var calendar: Calendar
@export var cargo_hold: CargoHold
@export var bank_account: BankAccount

signal mission_started(mission: Mission)
signal mission_succeeded(mission: Mission)
signal mission_failed(mission: Mission)
signal mission_forfeited(mission: Mission)

## Currently accepted missions.
var _missions: Array[Mission] = []

func get_current_missions() -> Array[Mission]:
    return self._missions.duplicate()

func start_mission(mission: Mission) -> void:
    self._missions.push_back(mission)
    mission.status = Mission.Status.STARTED
    self.mission_started.emit(mission)

func forfeit_mission(mission: Mission) -> void:
    assert(mission in self._missions, "Cannot forfeit a non-current mission")

    mission.status = Mission.Status.FORFEITED
    self._missions.erase(mission)
    self.mission_forfeited.emit(mission)

func _fail_mission(mission: Mission) -> void:
    assert(mission in self._missions, "Cannot fail a non-current mission")

    mission.status = Mission.Status.FAILED
    self._missions.erase(mission)
    self.mission_forfeited.emit(mission)

func _physics_process(_delta: float) -> void:
    # Duplicate before enumeration, as updating a mission's status might remove it
    for mission: Mission in self._missions.duplicate():
        self._evaluate_mission_status(mission)

func _evaluate_mission_status(mission: Mission) -> void:
    for commodity: Commodity in mission.cargo:
        var required_amount: int = mission.cargo[commodity]
        var actual_amount: int = self.cargo_hold.commodities.get(commodity, 0)

        if actual_amount < required_amount:
            mission.status = Mission.Status.FAILED
            self._missions.erase(mission)
            self.mission_failed.emit(mission)
            return
    
    # TODO: Deliver cargo to destination planet if player has landed

## See [SaveGame].
func save_to_dict() -> Dictionary:
    var result := {}
    result["missions"] = self._missions.map(func(mission: Mission) -> Dictionary:
        return mission.save_to_dict()
    )
    return result

## See [SaveGame].
func load_from_dict(dict: Dictionary) -> void:
    var mission_dicts: Array[Dictionary] = dict["missions"]
    self._missions = mission_dicts.map(func(mission_dict: Dictionary) -> Mission:
        var mission: Mission = Mission.new()
        mission.load_from_dict(mission_dict)
        return mission
    )
