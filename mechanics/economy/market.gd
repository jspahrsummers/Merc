extends Resource
class_name Market

## Describes a trading market.

## The [TradeAsset] used as money by this market, denominating the prices of all trades.
##
## This is most commonly a [Currency], but frontier worlds might prefer to trade in physical commodities instead.
@export var money: TradeAsset

## Any commodities that can be traded at the market, structured as a dictionary of [Commodity] keys to [float] [b]relative[/b] prices.
##
## Relative prices are expressed on a scale from 0 to 1, where 0 is extremely cheap relative to the commodity's base price, and 1 is extremely expensive.
@export var commodities: Dictionary
