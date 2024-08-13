extends Resource
class_name Planet

enum {
    BAR = 0b1,
    TRADING = 0b10,
    MISSIONS = 0b100,
    OUTFITTER = 0b1000,
    SHIPYARD = 0b1000_0,
    REFUEL = 0b1000_00,
}

## The name of this planet.
@export var name: String

## Facilities available on this planet.
@export_flags("Bar", "Trading", "Missions", "Outfitter", "Shipyard", "Refuel") var facilities: int = BAR | TRADING | MISSIONS | REFUEL

## A visual depiction of this planet's landscape.
@export var landscape_image: Texture2D

## A human-readable description of this planet, to present when landing.
##
## BBCode can be used to format this description.
@export_multiline var description: String

## A weak reference to the [StarSystem] that this planet exists within.
##
## This is populated when the star system is initialized.
var star_system: WeakRef

func _to_string() -> String:
    return "Planet:" + self.name
