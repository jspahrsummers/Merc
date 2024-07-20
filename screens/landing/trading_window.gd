extends Window

@export var market: Market
@export var tab_container: TabContainer

@export var commodities_container: Container
@export var currencies_container: Container

@export var trade_cell_scene: PackedScene

func _ready() -> void:
    self.tab_container.tabs_visible = self.market.currencies.size() > 0 and self.market.commodities.size() > 0

    for commodity: Commodity in self.market.commodities:
        var price: int = self.market.commodities.get(commodity, 0)

        var trade_cell: TradeCell = self.trade_cell_scene.instantiate()
        trade_cell.asset_label.text = commodity.name
        trade_cell.price_label.text = "x %s credits" % (float(price) / Currency.GRANULARITY)
        self.commodities_container.add_child(trade_cell)

    for currency: Currency in self.market.currencies:
        var price: int = self.market.currencies.get(currency, 0)

        var trade_cell: TradeCell = self.trade_cell_scene.instantiate()
        trade_cell.asset_label.text = currency.name
        trade_cell.price_label.text = "x %s credits" % (float(price) / Currency.GRANULARITY)
        self.currencies_container.add_child(trade_cell)
