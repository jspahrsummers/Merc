extends Resource
class_name BankAccount

## Represents a bank account or digital wallet of currencies.

## The currencies being held in the account, structured as a dictionary of [Currency] keys to [float] amounts.
@export var currencies: Dictionary

## Deposits [param amount] of [param currency] into the account.
func deposit(currency: Currency, amount: float) -> void:
    self.currencies[currency] = self.currencies.get(currency, 0.0) + amount
    self.emit_changed()

## Withdraws up to [param amount] of [param currency] from the account.
##
## Returns the amount actually withdrawn, which may be less than the requested if the balance is insufficient.
func withdraw_up_to(currency: Currency, amount: float) -> float:
    var available_amount: float = self.currencies.get(currency, 0.0)
    var withdrawn_amount := minf(amount, available_amount)
    if is_zero_approx(withdrawn_amount):
        return 0.0
    
    if is_equal_approx(withdrawn_amount, available_amount):
        self.currencies.erase(currency)
    else:
        self.currencies[currency] = available_amount - withdrawn_amount
    
    self.emit_changed()
    return withdrawn_amount

## Withdraws exactly [param amount] of [param currency] from the account.
##
## If [param allow_negative] is set, the account can go into negative balance; otherwise, an attempt to draw down more than the balance will fail and return false.
func withdraw_exactly(currency: Currency, amount: float, allow_negative: bool=false) -> bool:
    var available_amount: float = self.currencies.get(currency, 0.0)
    if available_amount - amount <= - Currency.EPSILON and not allow_negative:
        return false
    
    if is_equal_approx(available_amount, amount):
        self.currencies.erase(currency)
    else:
        self.currencies[currency] = available_amount - amount
    
    self.emit_changed()
    return true
