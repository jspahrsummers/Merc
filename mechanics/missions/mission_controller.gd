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
            cargo_hold.changed.disconnect(_check_all_missions_failure)
        cargo_hold = value
        if cargo_hold:
            cargo_hold.changed.connect(_check_all_missions_failure)
            self._check_all_missions_failure()

## Fires when the player starts a mission.
signal mission_started(mission: Mission)

## Fires when the player succeeds at a mission.
signal mission_succeeded(mission: Mission)

## Fires when the player fails a mission.
signal mission_failed(mission: Mission)

## Fires when the player forfeits a mission.
signal mission_forfeited(mission: Mission)

## Currently accepted missions.
var _missions: Array[Mission] = []

## Returns a copy of the player's current mission list.
func get_current_missions() -> Array[Mission]:
    return self._missions.duplicate()

## Starts a mission if the player has the required resources, or returns false if they don't have enough for the starting cost.
func start_mission(mission: Mission) -> bool:
    assert(mission not in self._missions, "Cannot start the same mission twice")

    for trade_asset: TradeAsset in mission.starting_cost:
        var required_amount: float = mission.starting_cost[trade_asset]
        if trade_asset.current_amount(self.cargo_hold, self.bank_account) < required_amount:
            return false
    
    var required_volume: float = 0.0
    for commodity: Commodity in mission.cargo:
        required_volume += mission.cargo[commodity] * commodity.volume

    if self.cargo_hold.get_occupied_volume() + required_volume > self.cargo_hold.max_volume:
        return false

    # Only update the amounts after checking
    for trade_asset: TradeAsset in mission.starting_cost:
        var required_amount: float = mission.starting_cost[trade_asset]
        var result := trade_asset.take_exactly(required_amount, self.cargo_hold, self.bank_account)
        assert(result, "Withdrawing mission starting cost should succeed after previous check")
    
    for commodity: Commodity in mission.cargo:
        var amount: int = mission.cargo[commodity]
        var result := self.cargo_hold.add_exactly(commodity, amount)
        assert(result, "Adding mission cargo should succeed after previous check")

    self._missions.push_back(mission)
    mission.status = Mission.Status.STARTED
    self.mission_started.emit(mission)
    return true

## Forfeit a mission that the player has started.
func forfeit_mission(mission: Mission) -> void:
    self._fail_mission(mission, Mission.Status.FORFEITED)

## Fail a mission that the player has started, with a configurable choice of status.
func _fail_mission(mission: Mission, failure_status: Mission.Status = Mission.Status.FAILED) -> void:
    assert(mission in self._missions, "Cannot fail a non-current mission")

    mission.status = failure_status

    # Ordering is important: do this before modifying cargo, so it doesn't participate in the update notification.
    self._missions.erase(mission)
    
    # TODO: Don't remove cargo from a forfeited mission(?), maybe the player wants to sell it on. But check this makes sense economically.
    for commodity: Commodity in mission.cargo:
        var amount: int = mission.cargo[commodity]
        self.cargo_hold.remove_up_to(commodity, amount)

    if failure_status == Mission.Status.FORFEITED:
        self.mission_forfeited.emit(mission)
    else:
        self.mission_failed.emit(mission)

## Mark a mission as succeeded, and pay out the proceeds.
func _succeed_mission(mission: Mission) -> void:
    assert(mission in self._missions, "Cannot succeed a non-current mission")

    mission.status = Mission.Status.SUCCEEDED

    # Ordering is important: do this before modifying cargo, so it doesn't participate in the update notification.
    self._missions.erase(mission)

    for commodity: Commodity in mission.cargo:
        var amount: int = mission.cargo[commodity]
        var result := self.cargo_hold.remove_exactly(commodity, amount)
        assert(result, "Expected cargo withdrawal to succeed when mission is succeeded")

    for trade_asset: TradeAsset in mission.monetary_reward:
        var amount: float = mission.monetary_reward[trade_asset]

        # TODO: This can fail if the player lacks cargo space. Deposit currency in lieu of commodities?
        trade_asset.add_up_to(amount, self.cargo_hold, self.bank_account)

    self.mission_succeeded.emit(mission)

## Evaluates all missions for failure conditions.
func _check_all_missions_failure() -> void:
    # Duplicate before enumeration, as updating a mission's status might remove it
    for mission: Mission in self._missions.duplicate():
        self._check_mission_failure(mission)

## Evaluates a specific mission against its failure conditions.
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
