extends Resource
class_name Planet

enum {
    BAR = 0x1,
    TRADING = 0x2,
    MISSIONS = 0x4,
    OUTFITTER = 0x8,
    SHIPYARD = 0x10,
    REFUEL = 0x20
}

## The name of this planet.
@export var name: String

## Facilities available on this planet.
@export_flags("Bar", "Trading", "Missions", "Outfitter", "Shipyard", "Refuel") var facilities: int = BAR|TRADING|MISSIONS|REFUEL
