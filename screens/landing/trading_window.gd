extends Window
class_name TradingWindow

@export var market: Market

@export var tab_container: TabContainer
@export var commodities_container: GridContainer
@export var trade_buttons_scene: PackedScene

var cargo_hold: CargoHold
var bank_account: BankAccount

# @export var currencies_container: Container

func _ready() -> void:
    var has_commodities := false
    var has_currencies := false

    var money_suffix := market.money.name.to_lower()

    for trade_asset: TradeAsset in self.market.trade_assets:
        var price: int = self.market.trade_assets[trade_asset]

        if trade_asset is Currency:
            has_currencies = true
            continue

        if not (trade_asset is Commodity):
            assert(false, "Unknown trade asset type: %s" % trade_asset)

        has_commodities = true

        var name_label := Label.new()
        name_label.text = trade_asset.name
        name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        self.commodities_container.add_child(name_label)

        var price_label := Label.new()
        price_label.text = "%s %s" % [float(price) / market.money.granularity, money_suffix]
        self.commodities_container.add_child(price_label)

        # TODO: Live update
        var cargo: int = self.cargo_hold.commodities.get(trade_asset, 0)
        var cargo_label := Label.new()
        cargo_label.text = str(cargo) if cargo else ""
        self.commodities_container.add_child(cargo_label)

        # TODO: Connect buttons
        var buttons: TradeButtons = self.trade_buttons_scene.instantiate()
        self.commodities_container.add_child(buttons)

    self.tab_container.tabs_visible = has_commodities and has_currencies

func _on_close_requested() -> void:
    self.visible = false
