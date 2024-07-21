extends Resource
class_name BankAccount

## Represents a bank account or digital wallet of currencies.

## The currencies being held in the account, structured as a dictionary of [Currency] keys to [int] amounts.
##
## Amounts are units of the [Currency] multiplied by its [member TradeAsset.granularity].
@export var currencies: Dictionary

## Deposits [param amount] of [param currency] into the account.
func deposit(currency: Currency, amount: int) -> void:
    self.currencies[currency] = self.currencies.get(currency, 0) + amount

## Withdraws up to [param amount] of [param currency] from the account.
##
## Returns the amount actually withdrawn, which may be less than the requested if the balance is insufficient.
func withdraw_up_to(currency: Currency, amount: int) -> int:
    var available_amount: int = self.currencies.get(currency, 0)
    var withdrawn_amount := mini(amount, available_amount)
    if withdrawn_amount == 0:
        return 0
    
    if withdrawn_amount == available_amount:
        self.currencies.erase(currency)
    else:
        self.currencies[currency] = available_amount - withdrawn_amount
    
    self.emit_changed()
    return withdrawn_amount

## Withdraws exactly [param amount] of [param currency] from the account.
##
## If [param allow_negative] is set, the account can go into negative balance; otherwise, an attempt to draw down more than the balance will fail and return false.
func withdraw_exactly(currency: Currency, amount: int, allow_negative: bool=false) -> bool:
    var available_amount: int = self.currencies.get(currency, 0)
    if available_amount < amount and not allow_negative:
        return false
    
    if available_amount == amount:
        self.currencies.erase(currency)
    else:
        self.currencies[currency] = available_amount - amount
    
    self.emit_changed()
    return true
