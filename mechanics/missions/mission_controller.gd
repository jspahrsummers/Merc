extends Node3D
class_name MissionController

## Manages mission status for the player.

var calendar: Calendar
var bank_account: BankAccount
var cargo_hold: CargoHold:
    set(value):
        if value == cargo_hold:
            return
        
        if cargo_hold:
            cargo_hold.changed.disconnect(_on_cargo_hold_changed)
        cargo_hold = value
        if cargo_hold:
            cargo_hold.changed.connect(_on_cargo_hold_changed)
            self._on_cargo_hold_changed()

signal mission_started(mission: Mission)
signal mission_succeeded(mission: Mission)
signal mission_failed(mission: Mission)
signal mission_forfeited(mission: Mission)

## Currently accepted missions.
var _missions: Array[Mission] = []

func get_current_missions() -> Array[Mission]:
    return self._missions.duplicate()

func start_mission(mission: Mission) -> bool:
    for trade_asset: TradeAsset in mission.starting_cost:
        var required_amount: float = mission.starting_cost[trade_asset]
        if trade_asset.current_amount(self.cargo_hold, self.bank_account) < required_amount:
            return false

    # Only withdraw the amounts after checking
    for trade_asset: TradeAsset in mission.starting_cost:
        var required_amount: float = mission.starting_cost[trade_asset]
        var result := trade_asset.take_exactly(required_amount, self.cargo_hold, self.bank_account)
        assert(result, "Withdrawing mission starting cost should succeed after previous check")

    self._missions.push_back(mission)
    mission.status = Mission.Status.STARTED
    self.mission_started.emit(mission)
    return true

func forfeit_mission(mission: Mission) -> void:
    self._fail_mission(mission, Mission.Status.FORFEITED)

func _fail_mission(mission: Mission, failure_status: Mission.Status = Mission.Status.FAILED) -> void:
    assert(mission in self._missions, "Cannot fail a non-current mission")

    mission.status = failure_status
    self._missions.erase(mission)
    self.mission_forfeited.emit(mission)

func _succeed_mission(mission: Mission) -> void:
    assert(mission in self._missions, "Cannot fail a non-current mission")

    mission.status = Mission.Status.SUCCEEDED
    self._missions.erase(mission)

    for trade_asset: TradeAsset in mission.monetary_reward:
        var amount: float = mission.monetary_reward[trade_asset]

        # TODO: This can fail if the player lacks cargo space. Deposit currency in lieu of commodities?
        trade_asset.add_up_to(amount, self.cargo_hold, self.bank_account)

    self.mission_succeeded.emit(mission)

func _on_cargo_hold_changed() -> void:
    self._check_all_missions_failure()

func _check_all_missions_failure() -> void:
    # Duplicate before enumeration, as updating a mission's status might remove it
    for mission: Mission in self._missions.duplicate():
        self._check_mission_failure(mission)

func _check_mission_failure(mission: Mission) -> void:
    for commodity: Commodity in mission.cargo:
        var required_amount: int = mission.cargo[commodity]
        var actual_amount: int = self.cargo_hold.commodities.get(commodity, 0)
        if actual_amount < required_amount:
            self._fail_mission(mission)
            return

func _on_player_landed(_player: Player, planet: Planet) -> void:
    for mission: Mission in self._missions.duplicate():
        if mission.destination_planet != planet:
            continue
        
        self._check_mission_failure(mission)
        if mission.status == Mission.Status.FAILED:
            continue

        for commodity: Commodity in mission.cargo:
            var required_amount: int = mission.cargo[commodity]
            var result := self.cargo_hold.remove_exactly(commodity, required_amount)
            assert(result, "Withdrawing mission cargo should succeed after previous failure check")
        
        self._succeed_mission(mission)

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
