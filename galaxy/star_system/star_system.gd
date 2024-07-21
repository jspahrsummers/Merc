extends Resource
class_name StarSystem

## Describes the non-visual characteristics of a single star system.
##
## Visual characteristics, pre-existing nodes, etc., should all be saved into a scene that matches the [method scene_path].

## The human-readable name of this star system.
@export var name: StringName

## All hyperspace connections that this system has to other systems.
@export var connections: Array[StringName] = []

## The position of this star system within the galaxy.
@export var position: Vector3

## The resource path to this star system's scene.
@export_file("*.tscn") var scene_path: String

## The trading market in this star system, if any.
@export var market: Market

## The [TradeAsset] used to pay for refueling, on planets where refueling is available.
##
## If [member refueling_cost] is 0, refueling is free and this property is ignored.
@export var refueling_money: TradeAsset

## The cost (per unit of hyperspace fuel) to refuel in this system, in units of [member refueling_money] multiplied by the money's [member TradeAsset.granularity].
@export var refueling_cost: int

## A weak reference to the [Galaxy] that this system is part of.
##
## This is populated when the galaxy is initialized.
var galaxy: WeakRef

func _to_string() -> String:
    return "StarSystem:" + self.name
