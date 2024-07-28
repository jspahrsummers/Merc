extends TradeAsset
class_name Currency

## Represents a digital currency that can be used to pay for goods and services.

## Epsilon for floating-point comparisons of currency values.
const EPSILON = 0.001

## How many credits one unit of this currency is worth.
@export var price_in_credits: float

## How many decimal places to compute in this currency, and to show when rendering.
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

func price_converted_from_credits(price: float) -> float:
    return self.round(price / self.price_in_credits)

func amount_as_string(amount: float) -> String:
    return "%s %s" % [self.round(amount), self.name.to_lower()]

## Rounds an amount of this currency to its [member precision].
func round(amount: float) -> float:
    return snappedf(amount, pow(10, -self.precision))

func _to_string() -> String:
    return "Currency:" + self.name
