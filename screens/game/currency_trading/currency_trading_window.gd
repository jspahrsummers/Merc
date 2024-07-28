extends Window
class_name CurrencyTradingWindow

@export var buy_spin_box: SpinBox
@export var buy_option_button: OptionButton
@export var buy_button: Button
@export var buy_balance_label: Label
@export var exchange_rate_label: Label
@export var sell_spin_box: SpinBox
@export var sell_option_button: OptionButton
@export var sell_button: Button
@export var sell_balance_label: Label

const CURRENCIES_DIRECTORY = "res://mechanics/economy/currencies/"

var bank_account: BankAccount
var _currencies: Array[Currency]

func _ready() -> void:
    self.bank_account.changed.connect(_update)
    self._currencies = self._load_all_currencies()

    for currency in self._currencies:
        self.buy_option_button.add_item(currency.name)
        self.sell_option_button.add_item(currency.name)
    
    self.buy_option_button.select(1)
    self.sell_option_button.select(0)

func _update() -> void:
    pass

func _on_close_requested() -> void:
    self.visible = false

func _load_all_currencies() -> Array[Currency]:
    var result: Array[Currency] = []

    for file in DirAccess.get_files_at(CURRENCIES_DIRECTORY):
        result.push_back(load("%s/%s" % [CURRENCIES_DIRECTORY, file]))

    return result
