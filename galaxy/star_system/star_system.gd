@tool
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

## All landable ports in this star system.
@export var ports: Array[Port] = []

## The trading market in this star system, if any.
@export var market: Market

## The [TradeAsset] used to pay for refueling, on ports where refueling is available.
##
## If this property is [code]null[/code], refueling is free and this property is ignored.
@export var refueling_money: TradeAsset

## The [i]relative[/i] price of refueling in this system.
##
## Relative prices are expressed on a scale from 0 to 1, where 0 is extremely cheap relative to the [member refueling_money]'s base price, and 1 is extremely expensive.
@export_range(0.0, 1.0) var refueling_relative_price: float = 0.5

## The base price of refueling, in credits, used to compute relative refueling prices across the galaxy and in other currencies.
const REFUELING_BASE_PRICE_IN_CREDITS = 100

## The maximum percentage the refueling price can deviate from the base price.
const REFUELING_PRICE_MAX_DEVIATION = 0.5

## A weak reference to the [Galaxy] that this system is part of.
##
## This is populated when the galaxy is initialized.
var galaxy: WeakRef

## Returns the price (per unit of hyperspace fuel) to refuel in this system, in units of [member refueling_money].
func refueling_price() -> float:
    if self.refueling_money == null:
        return 0

    var price_in_credits := MathUtils.relative_to_absolute_price(self.refueling_relative_price, self.REFUELING_BASE_PRICE_IN_CREDITS, self.REFUELING_PRICE_MAX_DEVIATION)
    return self.refueling_money.price_converted_from_credits(price_in_credits)

## Infers the preferred money in this star system, based either on its trading market or how refueling is paid.
##
## Returns null if it cannot be determined.
func preferred_money() -> TradeAsset:
    return self.market.money if self.market else self.refueling_money

func _init() -> void:
    self._connect_backref.call_deferred()

func _connect_backref() -> void:
    for port in self.ports:
        port.star_system = weakref(self)

func _to_string() -> String:
    return "StarSystem:" + self.name
