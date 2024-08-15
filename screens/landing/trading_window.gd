extends Window
class_name TradingWindow

@export var commodities_container: GridContainer
@export var trade_buttons_scene: PackedScene
@export var premultiplied_canvas_material: CanvasItemMaterial

var market: Market
var cargo_hold: CargoHold
var bank_account: BankAccount

var _quantity_labels: Dictionary = {}
var _trade_buttons: Dictionary = {}

func _ready() -> void:
    var commodities := self.market.commodities.keys()
    commodities.sort_custom(func(a: Commodity, b: Commodity) -> bool: return a.name < b.name)

    for commodity: Commodity in commodities:
        var price := self.market.price(commodity)

        var name_label := Label.new()
        name_label.material = self.premultiplied_canvas_material
        name_label.text = commodity.name
        name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        self.commodities_container.add_child(name_label)

        var price_label := Label.new()
        price_label.material = self.premultiplied_canvas_material
        price_label.text = market.money.amount_as_string(price)
        price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        self.commodities_container.add_child(price_label)

        var volume_label := Label.new()
        volume_label.material = self.premultiplied_canvas_material
        volume_label.text = "%s m³" % commodity.volume
        volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        self.commodities_container.add_child(volume_label)

        var quantity_label := Label.new()
        quantity_label.material = self.premultiplied_canvas_material
        self._quantity_labels[commodity] = quantity_label
        self.commodities_container.add_child(quantity_label)

        var buttons: TradeButtons = self.trade_buttons_scene.instantiate()
        buttons.buy_button.pressed.connect(func() -> void: self._buy(commodity))
        buttons.sell_button.pressed.connect(func() -> void: self._sell(commodity))
        self._trade_buttons[commodity] = buttons
        self.commodities_container.add_child(buttons)

    self.cargo_hold.changed.connect(_update)
    self.bank_account.changed.connect(_update)
    self._update()

func _on_close_requested() -> void:
    self.visible = false

func _update() -> void:
    for commodity: Commodity in self.market.commodities:
        var quantity_label: Label = self._quantity_labels[commodity]
        var quantity: int = self.cargo_hold.commodities.get(commodity, 0)
        quantity_label.text = "" if quantity == 0 else str(quantity)

        var price := self.market.price(commodity)
        var can_pay: bool = self.market.money.current_amount(self.cargo_hold, self.bank_account) - price >= Currency.EPSILON
        var can_carry := self.cargo_hold.get_occupied_volume() + commodity.volume <= self.cargo_hold.max_volume

        var buttons: TradeButtons = self._trade_buttons[commodity]
        buttons.buy_button.disabled = not can_pay or not can_carry
        buttons.sell_button.disabled = quantity == 0

func _buy(commodity: Commodity) -> void:
    var price := self.market.price(commodity)
    var desired_amount := self._desired_trade_amount()
    var available_amount := floori((self.cargo_hold.max_volume - self.cargo_hold.get_occupied_volume()) / commodity.volume)
    var trade_amount := mini(desired_amount, available_amount)

    var total_cost: float = price * trade_amount

    # Limit to current balance
    var actual_cost := minf(total_cost, self.market.money.current_amount(self.cargo_hold, self.bank_account))
    trade_amount = floori(actual_cost / price)
    assert(trade_amount <= available_amount, "Failed to limit trade amount to available space")

    var withdrew := self.market.money.take_exactly(trade_amount * price, self.cargo_hold, self.bank_account)
    assert(withdrew, "Failed to pay for trade")

    var deposited := self.cargo_hold.add_exactly(commodity, trade_amount)
    assert(deposited, "Failed to deposit cargo")

func _sell(commodity: Commodity) -> void:
    var price := self.market.price(commodity)
    var desired_amount := self._desired_trade_amount()
    var available_amount: int = self.cargo_hold.commodities.get(commodity, 0)
    var trade_amount := mini(desired_amount, available_amount)

    # Limit to maximum cargo space (bank accounts have no limit)
    var proceeds := self.market.money.add_up_to(trade_amount * price, self.cargo_hold, self.bank_account)

    var withdrew := self.cargo_hold.remove_exactly(commodity, floori(proceeds / price))
    assert(withdrew, "Failed to sell cargo")

func _desired_trade_amount() -> int:
    if Input.is_key_pressed(KEY_SHIFT):
        return 10
    else:
        return 1
