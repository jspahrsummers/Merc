extends TradeAsset
class_name Currency

## Represents a digital currency that can be used to pay for goods and services.

## Epsilon for floating-point comparisons of currency values.
const EPSILON = 0.001

## How many credits one unit of this currency is worth.
@export var price_in_credits: float

## How many decimal places to show when rendering amounts in this currency.
@export var precision: int

func current_amount(_cargo_hold: CargoHold, bank_account: BankAccount) -> float:
    return bank_account.currencies.get(self, 0.0)

func take_up_to(amount: float, _cargo_hold: CargoHold, bank_account: BankAccount) -> float:
    return bank_account.withdraw_up_to(self, amount)

func take_exactly(amount: float, _cargo_hold: CargoHold, bank_account: BankAccount, allow_negative: bool=false) -> bool:
    return bank_account.withdraw_exactly(self, amount, allow_negative)

func add_up_to(amount: float, _cargo_hold: CargoHold, bank_account: BankAccount) -> float:
    bank_account.deposit(self, amount)
    return amount

func add_exactly(amount: float, _cargo_hold: CargoHold, bank_account: BankAccount) -> bool:
    bank_account.deposit(self, amount)
    return true

func amount_as_string(amount: float) -> String:
    return "%.*f %s" % [self.precision, amount, self.name.to_lower()]

func _to_string() -> String:
    return "Currency:" + self.name
