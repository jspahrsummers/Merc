extends Window
class_name TradingWindow

@export var market: Market
@export var tab_container: TabContainer

@export var commodities_container: Container
@export var currencies_container: Container

@export var trade_cell_scene: PackedScene

func _ready() -> void:
    var has_commodities := false
    var has_currencies := false

    var money_suffix := market.money.name.to_lower()

    for trade_asset: TradeAsset in self.market.trade_assets:
        var price: int = self.market.trade_assets[trade_asset]

        var trade_cell: TradeCell = self.trade_cell_scene.instantiate()
        trade_cell.asset_label.text = trade_asset.name
        trade_cell.price_label.text = "x %s %s" % [float(price) / market.money.granularity, money_suffix]

        if trade_asset is Commodity:
            has_commodities = true
            self.commodities_container.add_child(trade_cell)
        elif trade_asset is Currency:
            has_currencies = true
            self.currencies_container.add_child(trade_cell)
        else:
            assert(false, "Unknown trade asset type: %s" % trade_asset)

    self.tab_container.tabs_visible = has_commodities and has_currencies
