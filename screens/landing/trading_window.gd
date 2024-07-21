extends Window
class_name TradingWindow

@export var market: Market

@export var tab_container: TabContainer
@export var commodities_container: GridContainer
@export var currencies_container: GridContainer
@export var trade_buttons_scene: PackedScene

var cargo_hold: CargoHold
var bank_account: BankAccount

var _quantity_labels_by_trade_asset: Dictionary = {}
var _trade_buttons_by_trade_asset: Dictionary = {}

func _ready() -> void:
    var has_commodities := false
    var has_currencies := false

    var money_suffix := market.money.name.to_lower()

    var trade_assets := self.market.trade_assets.keys()
    trade_assets.sort_custom(func(a: TradeAsset, b: TradeAsset) -> bool: return a.name < b.name)

    for trade_asset: TradeAsset in trade_assets:
        var price: int = self.market.trade_assets[trade_asset]

        var container: GridContainer
        if trade_asset is Currency:
            has_currencies = true
            container = self.currencies_container
        elif trade_asset is Commodity:
            has_commodities = true
            container = self.commodities_container
        else:
            assert(false, "Unknown trade asset type: %s" % trade_asset)

        var name_label := Label.new()
        name_label.text = trade_asset.name
        name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        container.add_child(name_label)

        var price_label := Label.new()
        price_label.text = "%s %s" % [float(price) / market.money.granularity, money_suffix]
        container.add_child(price_label)

        var quantity_label := Label.new()
        self._quantity_labels_by_trade_asset[trade_asset] = quantity_label
        container.add_child(quantity_label)

        var buttons: TradeButtons = self.trade_buttons_scene.instantiate()
        buttons.buy_button.pressed.connect(func() -> void: self._buy(trade_asset))
        buttons.sell_button.pressed.connect(func() -> void: self._sell(trade_asset))
        self._trade_buttons_by_trade_asset[trade_asset] = buttons
        container.add_child(buttons)

    self.tab_container.tabs_visible = has_commodities and has_currencies
    if not has_commodities:
        self.tab_container.current_tab = 1

    self.cargo_hold.changed.connect(_update_quantity_labels)

func _on_close_requested() -> void:
    self.visible = false

func _update_quantity_labels() -> void:
    for trade_asset: TradeAsset in self.market.trade_assets:
        var quantity_label: Label = self._quantity_labels_by_trade_asset[trade_asset]
        var quantity: int = trade_asset.current_amount(self.cargo_hold, self.bank_account)
        quantity_label.text = str(quantity) if quantity else ""

func _update_trade_buttons() -> void:
    pass

func _buy(trade_asset: TradeAsset) -> void:
    pass

func _sell(trade_asset: TradeAsset) -> void:
    pass
