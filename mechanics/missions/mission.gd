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

## A dictionary of [Commodity] keys to [int] amounts that the player must deliver to complete the mission.
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

static var _credits: Currency = preload("res://mechanics/economy/currencies/credits.tres")

## The amount to charge in starting cost, relative to the reward, for a randomly generated mission.
const _STARTING_COST_PERCENTAGE = 0.1

## Creates a random delivery mission without a deadline.
static func create_random_delivery_mission(galaxy: Galaxy, origin_planet: Planet) -> Mission:
    var mission := Mission.new()

    var origin_system: StarSystem = origin_planet.star_system.get_ref()
    var possible_destination_systems := galaxy.systems.filter(func(system: StarSystem) -> bool:
        return system.planets and system != origin_system)

    var destination_system: StarSystem = possible_destination_systems.pick_random()
    mission.destination_planet = destination_system.planets.pick_random()

    var commodity := Commodity.pick_random_special()
    var cargo_volume := randi_range(5, 20)
    var units := roundi(cargo_volume / commodity.volume)
    mission.cargo[commodity] = units

    mission.title = "Delivery to %s" % mission.destination_planet.name
    mission.description = "Transport %i %s to %s in the %s system." % [
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
