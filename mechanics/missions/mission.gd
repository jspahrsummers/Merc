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
@export var cargo: Dictionary

## A dictionary of [TradeAsset] keys to [float] amounts that the player will receive upon success.
@export var monetary_reward: Dictionary