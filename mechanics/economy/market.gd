extends Resource
class_name Market

## Describes a trading market.

## The [TradeAsset] used as money by this market, denominating the prices of all trades.
##
## This is most commonly a [Currency], but frontier worlds might prefer to trade in physical commodities instead.
@export var money: TradeAsset

## Any assets that can be traded at the market, structured as a dictionary of [TradeAsset] keys to [float] prices.
##
## Prices are units of [member money].
@export var trade_assets: Dictionary
