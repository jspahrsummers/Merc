extends SaveableResource
class_name PassengerQuarters

## Represents passenger quarters on a ship.

## The total number of passenger spaces available.
@export var total_spaces: int:
    set(value):
        assert(value >= 0, "Total spaces must be non-negative")
        if total_spaces == value:
            return

        total_spaces = value
        self.emit_changed()

## The number of passenger spaces currently occupied.
@export var occupied_spaces: int:
    set(value):
        assert(value >= 0 and value <= total_spaces, "Occupied spaces must be between 0 and total spaces")
        if occupied_spaces == value:
            return

        occupied_spaces = value
        self.emit_changed()

## Attempts to add exactly [param count] passengers, or returns false if there's not enough space.
func add_passengers(count: int) -> bool:
    if self.occupied_spaces + count > self.total_spaces:
        return false

    self.occupied_spaces += count
    return true

## Attempts to remove exactly [param count] passengers, or returns false if there aren't that many passengers.
func remove_passengers(count: int) -> bool:
    if count < self.occupied_spaces:
        return false

    self.occupied_spaces -= count
    return true
