extends Window
class_name CurrencyTradingWindow

@export var buy_spin_box: SpinBox
@export var buy_option_button: OptionButton
@export var buy_balance_label: Label
@export var trade_button: Button
@export var sell_spin_box: SpinBox
@export var sell_option_button: OptionButton
@export var sell_balance_label: Label

const CURRENCIES_DIRECTORY = "res://mechanics/economy/currencies/"

var bank_account: BankAccount
var _currencies: Array[Currency]
var _updating: bool

func _ready() -> void:
    self._updating = true
    self.bank_account.changed.connect(_update)
    self._currencies = self._load_all_currencies()

    for currency in self._currencies:
        self.buy_option_button.add_item(currency.name)
        self.sell_option_button.add_item(currency.name)
    
    self.buy_option_button.select(1)
    self.sell_option_button.select(0)
    self._updating = false

    self._update()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_currency_trading"):
        self.get_viewport().set_input_as_handled()
        self.queue_free()

func _get_buy_currency() -> Currency:
    return self._currencies[self.buy_option_button.selected] if self.buy_option_button.selected >= 0 else null

func _get_sell_currency() -> Currency:
    return self._currencies[self.sell_option_button.selected] if self.sell_option_button.selected >= 0 else null

func _on_trade_button_pressed() -> void:
    var buy_currency: Currency = self._get_buy_currency()
    var sell_currency: Currency = self._get_sell_currency()
    assert(buy_currency and sell_currency and buy_currency != sell_currency, "Expected to have distinct currencies set for buying and selling")

    self._updating = true

    var price := buy_currency.price_in_credits / sell_currency.price_in_credits
    var withdrew := self.bank_account.withdraw_up_to(sell_currency, self.sell_spin_box.value)
    self.bank_account.deposit(buy_currency, withdrew * price)

    self._updating = false
    self._update()

func _on_buy_option_button_item_selected(_index: int) -> void:
    if self._updating:
        return

    self._update()
    self._update_buy_spin_box_value()

func _on_buy_spin_box_value_changed(_value: float) -> void:
    self._update_sell_spin_box_value()

func _update_sell_spin_box_value() -> void:
    if self._updating:
        return
    
    self._updating = true

    var buy_currency: Currency = self._get_buy_currency()
    var sell_currency: Currency = self._get_sell_currency()
    if buy_currency and sell_currency and buy_currency != sell_currency:
        self.sell_spin_box.value = sell_currency.round(self.buy_spin_box.value * buy_currency.price_in_other_currency(sell_currency))
    
    self._updating = false

func _on_sell_option_button_item_selected(_index: int) -> void:
    if self._updating:
        return

    self._update()
    self._update_sell_spin_box_value()

func _on_sell_spin_box_value_changed(_value: float) -> void:
    self._update_buy_spin_box_value()

func _update_buy_spin_box_value() -> void:
    if self._updating:
        return
    
    self._updating = true

    var buy_currency: Currency = self._get_buy_currency()
    var sell_currency: Currency = self._get_sell_currency()
    if buy_currency and sell_currency and buy_currency != sell_currency:
        self.buy_spin_box.value = buy_currency.round(self.sell_spin_box.value * sell_currency.price_in_other_currency(buy_currency))
    
    self._updating = false

func _update() -> void:
    self._updating = true

    var buy_currency: Currency = self._get_buy_currency()
    var sell_currency: Currency = self._get_sell_currency()

    if buy_currency:
        var balance: float = self.bank_account.currencies.get(buy_currency, 0.0)
        self.buy_balance_label.text = "Balance: %s" % buy_currency.amount_as_string(balance)
        self.buy_spin_box.step = pow(10, -buy_currency.precision)
    else:
        self.buy_balance_label.text = ""
    
    if sell_currency:
        var balance: float = self.bank_account.currencies.get(sell_currency, 0.0)
        self.sell_balance_label.text = "Balance: %s" % sell_currency.amount_as_string(balance)
        self.sell_spin_box.step = pow(10, -sell_currency.precision)
    else:
        self.sell_balance_label.text = ""
    
    if buy_currency and sell_currency and buy_currency != sell_currency:
        var sell_balance: float = self.bank_account.currencies.get(sell_currency, 0.0)

        self.trade_button.disabled = sell_balance < buy_currency.price_in_other_currency(sell_currency)
        self.buy_spin_box.max_value = buy_currency.round(sell_balance * sell_currency.price_in_other_currency(buy_currency))
        self.sell_spin_box.max_value = sell_balance
    else:
        self.trade_button.disabled = true
    
    self._updating = false

func _on_close_requested() -> void:
    self.queue_free()

func _load_all_currencies() -> Array[Currency]:
    var result: Array[Currency] = []

    for file in DirAccess.get_files_at(CURRENCIES_DIRECTORY):
        result.push_back(load("%s/%s" % [CURRENCIES_DIRECTORY, file]))

    return result
