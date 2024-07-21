extends TradeAsset
class_name Currency

## Represents a digital currency that can be used to pay for goods and services.

## Epsilon for floating-point comparisons of currency values.
const EPSILON = 0.001

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

func _to_string() -> String:
    return "Currency:" + self.name
