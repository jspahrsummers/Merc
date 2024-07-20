extends Resource
class_name Market

## Describes a trading market (e.g., on a planet).

## The main currency used by this market, denominating the prices of all trades.
@export var main_currency: Currency

## Any currencies that can be traded at the market, structured as a dictionary of [Currency] keys to [int] prices.
##
## Prices are denominated in [constant Currency.GRANULARITY] sub-units of the [member main_currency].
@export var currencies: Dictionary

## Any commodities that can be traded at the market, structured as a dictionary of [Commodity] keys to [int] prices.
##
## Prices are denominated in [constant Currency.GRANULARITY] sub-units of the [member main_currency].
@export var commodities: Dictionary
