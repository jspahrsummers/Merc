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

## The human-readable title of the mission.
@export var title: String

## The human-readable mission description.
##
## BBCode can be used to format this description.
@export var description: String

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

## A destination to deliver cargo to.
@export var destination_planet: Planet:
    set(value):
        if value == destination_planet:
            return

        destination_planet = value
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

## Creates a random delivery mission without a deadline.
static func create_delivery_mission(origin_planet: Planet) -> Mission:
    var mission := Mission.new()

    var origin_system: StarSystem = origin_planet.star_system.get_ref()
    var galaxy: Galaxy = origin_system.galaxy.get_ref()
    var possible_destination_systems := galaxy.systems.filter(func(system: StarSystem) -> bool:
        return system.planets and system != origin_system)

    var destination_system: StarSystem = possible_destination_systems.pick_random()
    mission.destination_planet = destination_system.planets.pick_random()

    var commodity := Commodity.pick_random_special()
    var cargo_volume := randi_range(5, 20)
    var units := roundi(cargo_volume / commodity.volume)
    mission.cargo[commodity] = units

    mission.title = "Delivery to %s" % mission.destination_planet.name
    mission.description = "Transport %s %s to %s in the %s system." % [
        units,
        commodity.name,
        mission.destination_planet.name,
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

## Traveling-salesperson-suboptimal algorithm…
static func _randomly_walk_systems(galaxy: Galaxy, path_so_far: Array[StarSystem]) -> Array[StarSystem]:
    var last_system := path_so_far[-1]
    var allowed_connections := last_system.connections.filter(func(connection: StringName) -> bool:
        return not path_so_far.any(func(system: StarSystem) -> bool:
            return system.name == connection
        ))

    if allowed_connections.is_empty():
        return []

    var next_name: StringName = allowed_connections.pick_random()
    var next_system := galaxy.get_system(next_name)
    var new_path := path_so_far.duplicate()
    new_path.push_back(next_system)

    if randf() >= _RUSH_DELIVERY_ADD_HOP_CHANCE:
        # Add more hops to the path.
        var possible_path := Mission._randomly_walk_systems(galaxy, new_path)
        if possible_path:
            new_path = possible_path

    # Return the longest path that ends in a planetary system.
    while not new_path[-1].planets:
        new_path.pop_back()

        if new_path.size() <= 1:
            # Back to the starting point, so give up.
            return []

    return new_path

## Creates a random rush delivery mission.
##
## Note: this may not succeed every time, so ensure that the return value is checked.
static func create_rush_delivery_mission(origin_planet: Planet, calendar: Calendar) -> Mission:
    var origin_system: StarSystem = origin_planet.star_system.get_ref()
    var galaxy: Galaxy = origin_system.galaxy.get_ref()

    var path := Mission._randomly_walk_systems(galaxy, [origin_system])
    if not path:
        return null

    var mission := Mission.new()
    mission.deadline_cycle = calendar.get_current_cycle()
    for i in path.size() - 1:
        mission.deadline_cycle += HyperspaceSceneSwitcher.HYPERSPACE_APPROXIMATE_TRAVEL_DAYS * 24 * randf_range(_RUSH_DELIVERY_MIN_DEADLINE_BUFFER, _RUSH_DELIVERY_MAX_DEADLINE_BUFFER)

    var destination_system: StarSystem = path[-1]
    assert(destination_system != origin_system, "Cannot create rush delivery to the system we started in")

    mission.destination_planet = destination_system.planets.pick_random()

    var commodity := Commodity.pick_random_special()
    var cargo_volume := randi_range(5, 20)
    var units := roundi(cargo_volume / commodity.volume)
    mission.cargo[commodity] = units

    mission.title = "Rush delivery to %s" % mission.destination_planet.name
    mission.description = "Transport %s %s to %s in the %s system before %s." % [
        units,
        commodity.name,
        mission.destination_planet.name,
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

const _BOUNTY_MIN_CREDITS_REWARD = 15000
const _BOUNTY_MAX_CREDITS_REWARD = 40000

## Creates a random bounty mission.
static func create_bounty_mission() -> Mission:
    var mission := Mission.new()

    mission.assassination_target = Hero.pick_random_bounty()
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
static func create_random_mission(origin_planet: Planet, calendar: Calendar) -> Mission:
    var generators := [
        func() -> Mission: return Mission.create_bounty_mission(),
        func() -> Mission: return Mission.create_rush_delivery_mission(origin_planet, calendar),
    ]

    # Lazy way of weighting the random generation
    for i in range(2):
        generators.append(
            func() -> Mission: return Mission.create_delivery_mission(origin_planet),
        )

    var generator: Callable = generators.pick_random()
    return generator.call()

# Overridden because dictionaries of resources do not serialize correctly.
func save_to_dict() -> Dictionary:
    var result := {}
    result["title"] = self.title
    result["description"] = self.description

    if is_finite(self.deadline_cycle):
        result["deadline_cycle"] = self.deadline_cycle

    result["status"] = self.status

    if self.destination_planet:
        result["destination_planet"] = self.destination_planet.resource_path
    if self.assassination_target:
        result["assassination_target"] = self.assassination_target.resource_path

    result["cargo"] = SaveGame.serialize_dictionary_with_resource_keys(self.cargo)
    result["monetary_reward"] = SaveGame.serialize_dictionary_with_resource_keys(self.monetary_reward)
    result["starting_cost"] = SaveGame.serialize_dictionary_with_resource_keys(self.starting_cost)

    return result

func load_from_dict(dict: Dictionary) -> void:
    self.title = dict["title"]
    self.description = dict["description"]
    self.deadline_cycle = dict["deadline_cycle"] if "deadline_cycle" in dict else INF
    self.status = dict["status"]

    if "destination_planet" in dict:
        var path: String = dict["destination_planet"]
        self.destination_planet = ResourceUtils.safe_load_resource(path, "tres")

    if "assassination_target" in dict:
        var path: String = dict["assassination_target"]
        self.assassination_target = ResourceUtils.safe_load_resource(path, "tres")

    var saved_cargo: Dictionary = dict["cargo"]
    self.cargo = SaveGame.deserialize_dictionary_with_resource_keys(saved_cargo)

    var saved_reward: Dictionary = dict["monetary_reward"]
    self.monetary_reward = SaveGame.deserialize_dictionary_with_resource_keys(saved_reward)

    var saved_cost: Dictionary = dict["starting_cost"]
    self.starting_cost = SaveGame.deserialize_dictionary_with_resource_keys(saved_cost)

    self.emit_changed()
