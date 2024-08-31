extends Resource
class_name Port

enum {
    BAR = 0b1,
    TRADING = 0b10,
    MISSIONS = 0b100,
    OUTFITTER = 0b1000,
    SHIPYARD = 0b1000_0,
    REFUEL = 0b1000_00,
}

## The name of this port.
@export var name: String

## Facilities available on this port.
@export_flags("Bar", "Trading", "Missions", "Outfitter", "Shipyard", "Refuel") var facilities: int = BAR | TRADING | MISSIONS | REFUEL

## A visual depiction of this port's landscape.
@export var landscape_image: Texture2D

## A human-readable description of this port, to present when landing.
##
## BBCode can be used to format this description.
@export_multiline var description: String

## Outfits available at this port.
@export var available_outfits: Array[Outfit]

## A weak reference to the [StarSystem] that this port exists within.
##
## This is populated when the star system is initialized.
var star_system: WeakRef

func _to_string() -> String:
    return "Port:" + self.name
