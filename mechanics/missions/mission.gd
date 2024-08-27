extends SaveableResource
class_name Mission

## A mission that the player can undertake, with a notion of success and failure.

## The statuses that a mission can be in.
##
## Note that these values are saved via [SaveGame], so be careful not to break backwards compatibility!
enum Status {
    NOT_ACCEPTED = 0,
    STARTED = 1,
    SUCCEEDED = 2,
    FAILED = 3,
    FORFEITED = 4
}

## Broad types of missions.
##
## Note that these values are saved via [SaveGame], so be careful not to break backwards compatibility!
enum Type {
    DELIVERY = 0,
    RUSH_DELIVERY = 1,
    FERRY = 2,
    BOUNTY = 3,
}

## The human-readable title of the mission.
@export var title: String

## The human-readable mission description.
##
## BBCode can be used to format this description.
@export var description: String

## The type of this mission.
@export var type: Type

## A deadline for the mission, in GST cycles (see [Calendar]), or [constant INF] if there is no deadline.
##
## If the mission is not completed by this time, it is considered failed.
@export var deadline_cycle: float = INF:
    set(value):
        if is_equal_approx(value, deadline_cycle):
            return

        deadline_cycle = value
        self.emit_changed()

## The current status of the mission.
@export var status: Status = Status.NOT_ACCEPTED:
    set(value):
        if value == status:
            return

        match value:
            Status.SUCCEEDED, Status.FAILED, Status.FORFEITED:
                assert(status == Status.STARTED, "Illegal mission status transition from %s to %s" % [status, value])

            Status.STARTED:
                assert(status == Status.NOT_ACCEPTED, "Illegal mission status transition from %s to %s" % [status, value])

        status = value
        self.emit_changed()

## A dictionary of [Commodity] keys to [int] amounts that the player can deliver to complete the mission.
##
## If both this and [member assassination_target] are set, the player can choose which to complete the mission with.
@export var cargo: Dictionary:
    set(value):
        if is_same(value, cargo):
            return

        cargo = value.duplicate()
        cargo.make_read_only()
        self.emit_changed()

## The number of passengers to transport for this mission.
@export var passengers: int = 0:
    set(value):
        if passengers == value:
            return

        passengers = value
        self.emit_changed()

## A destination to deliver cargo or passengers to.
@export var destination_port: Port:
    set(value):
        if value == destination_port:
            return

        destination_port = value
        self.emit_changed()

## A dictionary of [TradeAsset] keys to [float] amounts that the player will receive upon success.
@export var monetary_reward: Dictionary:
    set(value):
        if is_same(value, monetary_reward):
            return

        monetary_reward = value.duplicate()
        monetary_reward.make_read_only()
        self.emit_changed()

## A dictionary of [TradeAsset] keys to [float] amounts the player must pay in order to start the mission.
##
## In-universe, this covers the cost of goods, should the player fail or forfeit the mission.
@export var starting_cost: Dictionary:
    set(value):
        if is_same(value, starting_cost):
            return

        starting_cost = value.duplicate()
        starting_cost.make_read_only()
        self.emit_changed()

## A hero that the player can kill in combat in order to complete the mission.
##
## If both this and [member cargo] are set, the player can choose which to complete the mission with.
@export var assassination_target: Hero:
    set(value):
        if value == assassination_target:
            return

        assassination_target = value
        self.emit_changed()

static var _credits: Currency = preload("res://mechanics/economy/currencies/credits.tres")

## The amount to charge in starting cost, relative to the cost of goods, for a randomly generated mission.
const _STARTING_COST_PERCENTAGE = 0.15

## The extra risk and reward factor for a rush delivery mission, on top of what the goods themselves are worth.
const _RUSH_DELIVERY_EXTRA_RISK_REWARD = 1.5

## Percentage chance of adding another hop to a rush delivery, when creating a random mission.
const _RUSH_DELIVERY_ADD_HOP_CHANCE = 0.5

## Minimum multiplier for a rush delivery's deadline, as computed by the number of hyperspace jumps required.
const _RUSH_DELIVERY_MIN_DEADLINE_BUFFER = 1.1

## Maximum multiplier for a rush delivery's deadline, as computed by the number of hyperspace jumps required.
const _RUSH_DELIVERY_MAX_DEADLINE_BUFFER = 1.5

## Base reward per passenger (in credits) for ferry missions.
const _FERRY_BASE_PRICE_PER_PASSENGER = 1000

## Minimum reward (in credits) for bounty missions.
const _BOUNTY_MIN_CREDITS_REWARD = 15000

## Maximum reward (in credits) for bounty missions.
const _BOUNTY_MAX_CREDITS_REWARD = 40000

# Mission type weights
const _MISSION_WEIGHTS = {
    Type.DELIVERY: 1.0,
    Type.RUSH_DELIVERY: 0.7,
    Type.FERRY: 1.0,
    Type.BOUNTY: 0.2,
}

## Creates a random delivery mission without a deadline.
static func create_delivery_mission(origin_port: Port) -> Mission:
    var mission := Mission.new()
    mission.type = Type.DELIVERY

    var origin_system: StarSystem = origin_port.star_system.get_ref()
    var galaxy: Galaxy = origin_system.galaxy.get_ref()
    var possible_destination_systems := galaxy.systems.filter(func(system: StarSystem) -> bool:
        return system.ports and system != origin_system)

    var destination_system: StarSystem = possible_destination_systems.pick_random()
    mission.destination_port = destination_system.ports.pick_random()

    var commodity := Commodity.pick_random_special()
    var cargo_volume := randi_range(5, 20)
    var units := roundi(cargo_volume / commodity.volume)
    mission.cargo[commodity] = units

    mission.title = "Delivery to %s" % mission.destination_port.name
    mission.description = "Transport %s %s to %s in the %s system." % [
        units,
        commodity.name,
        mission.destination_port.name,
        destination_system.name,
    ]

    var reward_money := destination_system.preferred_money()
    if not reward_money:
        reward_money = _credits

    mission.monetary_reward = {
        reward_money: round(reward_money.price_converted_from_credits(commodity.base_price_in_credits) * units)
    }

    var starting_money := origin_system.preferred_money()
    if not starting_money:
        starting_money = _credits

    mission.starting_cost = {
        starting_money: round(starting_money.price_converted_from_credits(commodity.base_price_in_credits) * units * _STARTING_COST_PERCENTAGE)
    }

    return mission

## Creates a random ferry passengers mission.
static func create_ferry_mission(origin_port: Port) -> Mission:
    var mission := Mission.new()
    mission.type = Type.FERRY

    var origin_system: StarSystem = origin_port.star_system.get_ref()
    var galaxy: Galaxy = origin_system.galaxy.get_ref()
    var possible_destination_systems := galaxy.systems.filter(func(system: StarSystem) -> bool:
        return system.ports and system != origin_system)

    var destination_system: StarSystem = possible_destination_systems.pick_random()
    mission.destination_port = destination_system.ports.pick_random()

    mission.passengers = randi_range(1, 10)

    mission.title = "Ferry passengers to %s" % mission.destination_port.name
    mission.description = "Transport %d passenger%s to %s in the %s system." % [
        mission.passengers,
        "s" if mission.passengers > 1 else "",
        mission.destination_port.name,
        destination_system.name,
    ]

    var reward_money := destination_system.preferred_money()
    if not reward_money:
        reward_money = _credits

    var base_reward := _FERRY_BASE_PRICE_PER_PASSENGER * mission.passengers
    mission.monetary_reward = {
        reward_money: round(reward_money.price_converted_from_credits(base_reward))
    }

    return mission

## Generates a random path through the galaxy, starting from the origin system.
## Returns an array of StarSystems representing the path.
static func _generate_random_path(origin_system: StarSystem, min_jumps: int, max_jumps: int) -> Array[StarSystem]:
    var galaxy: Galaxy = origin_system.galaxy.get_ref()
    var queue: Array[Array] = [[origin_system]] # Queue of paths
    var visited: Dictionary = {origin_system.name: true}
    var valid_paths: Array[Array] = []
    
    while not queue.is_empty():
        var current_path: Array = queue.pop_front()
        var current_system: StarSystem = current_path[-1]
        
        if current_path.size() > 1: # Don't count the origin system
            if current_system.ports and current_path.size() >= min_jumps:
                valid_paths.append(current_path)
            
            if current_path.size() == max_jumps:
                continue # Don't explore further if we've reached the maximum path length
        
        # Explore neighbors
        var neighbors := current_system.connections.duplicate()
        neighbors.shuffle() # Randomize the order of exploration
        
        for neighbor_name: StringName in neighbors:
            if neighbor_name in visited:
                continue
            
            var neighbor_system := galaxy.get_system(neighbor_name)
            var new_path := current_path.duplicate()
            new_path.append(neighbor_system)
            queue.append(new_path)
            visited[neighbor_name] = true
    
    if valid_paths.is_empty():
        return []
    

    return valid_paths.pick_random()

## Creates a random rush delivery mission.
##
## Note: this may not succeed every time, so ensure that the return value is checked.
static func create_rush_delivery_mission(origin_port: Port, calendar: Calendar) -> Mission:
    var origin_system: StarSystem = origin_port.star_system.get_ref()
    var path := _generate_random_path(origin_system, 2, 5) # Min 2 jumps, max 5 jumps
    
    if path.is_empty():
        return null

    var mission := Mission.new()
    mission.type = Type.RUSH_DELIVERY

    mission.deadline_cycle = calendar.get_current_cycle()
    for i in range(path.size()):
        mission.deadline_cycle += HyperspaceSceneSwitcher.HYPERSPACE_APPROXIMATE_TRAVEL_DAYS * 24 * randf_range(_RUSH_DELIVERY_MIN_DEADLINE_BUFFER, _RUSH_DELIVERY_MAX_DEADLINE_BUFFER)

    var destination_system: StarSystem = path[-1]
    assert(destination_system != origin_system, "Cannot create rush delivery to the system we started in")

    mission.destination_port = destination_system.ports.pick_random()

    var commodity := Commodity.pick_random_special()
    var cargo_volume := randi_range(5, 20)
    var units := roundi(cargo_volume / commodity.volume)
    mission.cargo[commodity] = units

    mission.title = "Rush delivery to %s" % mission.destination_port.name
    mission.description = "Transport %s %s to %s in the %s system before %s." % [
        units,
        commodity.name,
        mission.destination_port.name,
        destination_system.name,
        Calendar.format_gst(mission.deadline_cycle),
    ]

    var reward_money := destination_system.preferred_money()
    if not reward_money:
        reward_money = _credits

    mission.monetary_reward = {
        reward_money: round(reward_money.price_converted_from_credits(commodity.base_price_in_credits) * _RUSH_DELIVERY_EXTRA_RISK_REWARD * units)
    }

    var starting_money := origin_system.preferred_money()
    if not starting_money:
        starting_money = _credits

    mission.starting_cost = {
        starting_money: round(starting_money.price_converted_from_credits(commodity.base_price_in_credits) * _RUSH_DELIVERY_EXTRA_RISK_REWARD * units * _STARTING_COST_PERCENTAGE)
    }

    return mission

## Creates a random bounty mission.
##
## Note: this may not succeed every time, so ensure that the return value is checked.
static func create_bounty_mission(hero_roster: HeroRoster) -> Mission:
    var mission := Mission.new()
    mission.type = Type.BOUNTY

    mission.assassination_target = hero_roster.pick_random_bounty()
    if not mission.assassination_target:
        return null

    mission.title = "Bounty on %s" % mission.assassination_target.name
    mission.description = "%s has been raiding trading vessels in the area. A local trade union has scraped together a reward for whoever can put an end to their piracy." % mission.assassination_target.name

    var reward_credits := randi_range(_BOUNTY_MIN_CREDITS_REWARD, _BOUNTY_MAX_CREDITS_REWARD)

    mission.monetary_reward = {
        _credits: reward_credits
    }

    return mission

## Creates a random mission of any type.
##
## Note: this may not succeed every time, so ensure that the return value is checked.
static func create_random_mission(origin_port: Port, calendar: Calendar, hero_roster: HeroRoster) -> Mission:
    var mission_type: Type = CollectionUtils.weighted_random_choice(_MISSION_WEIGHTS)

    match mission_type:
        Type.DELIVERY:
            return create_delivery_mission(origin_port)
        Type.RUSH_DELIVERY:
            return create_rush_delivery_mission(origin_port, calendar)
        Type.FERRY:
            return create_ferry_mission(origin_port)
        Type.BOUNTY:
            return create_bounty_mission(hero_roster)
    
    assert(false, "Invalid mission type %s picked" % mission_type)
    return null

## Filters out any missions from [param proposed_missions] that are incompatible with [param current_missions] or one of the other proposed missions.
static func filter_incompatible_missions(current_missions: Array[Mission], proposed_missions: Array[Mission]) -> Array[Mission]:
    var bounties: Array[Hero] = []
    for mission in current_missions:
        if mission.assassination_target:
            bounties.append(mission.assassination_target)

    var filtered_missions: Array[Mission] = []
    for mission in proposed_missions:
        if mission.assassination_target and bounties.has(mission.assassination_target):
            continue

        filtered_missions.append(mission)

    return filtered_missions

# Overridden because dictionaries of resources do not serialize correctly.
func save_to_dict() -> Dictionary:
    var result := {}
    result["title"] = self.title
    result["description"] = self.description
    result["type"] = self.type

    if is_finite(self.deadline_cycle):
        result["deadline_cycle"] = self.deadline_cycle

    result["status"] = self.status

    if self.destination_port:
        result["destination_port"] = self.destination_port.resource_path
    if self.assassination_target:
        result["assassination_target"] = self.assassination_target.resource_path

    result["cargo"] = SaveGame.serialize_dictionary_with_resource_keys(self.cargo)
    result["monetary_reward"] = SaveGame.serialize_dictionary_with_resource_keys(self.monetary_reward)
    result["starting_cost"] = SaveGame.serialize_dictionary_with_resource_keys(self.starting_cost)
    result["passengers"] = self.passengers

    return result

func load_from_dict(dict: Dictionary) -> void:
    self.title = dict["title"]
    self.description = dict["description"]
    self.type = dict["type"]
    self.deadline_cycle = dict["deadline_cycle"] if "deadline_cycle" in dict else INF
    self.status = dict["status"]

    if "destination_port" in dict:
        var path: String = dict["destination_port"]
        self.destination_port = ResourceUtils.safe_load_resource(path, "tres")

    if "assassination_target" in dict:
        var path: String = dict["assassination_target"]
        self.assassination_target = ResourceUtils.safe_load_resource(path, "tres")

    var saved_cargo: Dictionary = dict["cargo"]
    self.cargo = SaveGame.deserialize_dictionary_with_resource_keys(saved_cargo)

    var saved_reward: Dictionary = dict["monetary_reward"]
    self.monetary_reward = SaveGame.deserialize_dictionary_with_resource_keys(saved_reward)

    var saved_cost: Dictionary = dict["starting_cost"]
    self.starting_cost = SaveGame.deserialize_dictionary_with_resource_keys(saved_cost)

    self.passengers = dict["passengers"] if "passengers" in dict else 0

    self.emit_changed()
