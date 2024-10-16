extends Resource
class_name TradeAsset

## Represents any asset that can be traded.

## The human-readable name for this asset.
@export var name: String

## Returns how much of this asset is in the [CargoHold] or [BankAccount], whichever is appropriate.
func current_amount(_cargo_hold: CargoHold, _bank_account: BankAccount) -> float:
    assert(false, "Meant to be implemented by subclasses")
    return 0

## Takes up to the specified amount of this asset from a [CargoHold] or [BankAccount], whichever is appropriate.
##
## Returns the amount actually taken, which may be less than requested if there's not enough.
func take_up_to(_amount: float, _cargo_hold: CargoHold, _bank_account: BankAccount) -> float:
    assert(false, "Meant to be implemented by subclasses")
    return 0

## Takes exactly the specified amount of this asset from a [CargoHold] or [BankAccount], whichever is appropriate.
##
## If [param allow_negative] is set [b]and[/b] this [TradeAsset] is a [Currency], the account can go into negative balance; otherwise, an attempt to take more than what's available will fail and return false.
func take_exactly(_amount: float, _cargo_hold: CargoHold, _bank_account: BankAccount, _allow_negative: bool = false) -> bool:
    assert(false, "Meant to be implemented by subclasses")
    return false

## Adds up to the specified amount of this asset to a [CargoHold] or [BankAccount], whichever is appropriate.
##
## Returns the amount actually added, which may be less than requested for commodities if there's not enough room in the cargo hold.
func add_up_to(_amount: float, _cargo_hold: CargoHold, _bank_account: BankAccount) -> float:
    assert(false, "Meant to be implemented by subclasses")
    return 0

## Adds exactly the specified amount of this asset to a [CargoHold] or [BankAccount], whichever is appropriate.
##
## If adding to a cargo hold, and there is not enough room, the operation will fail and return false.
func add_exactly(_amount: float, _cargo_hold: CargoHold, _bank_account: BankAccount) -> bool:
    assert(false, "Meant to be implemented by subclasses")
    return false

## Converts a price denominated in credits into a price denominated by this asset.
func price_converted_from_credits(_price_in_credits: float) -> float:
    assert(false, "Meant to be implemented by subclasses")
    return NAN

## Displays an amount of this asset in human-readable format.
func amount_as_string(amount: float) -> String:
    return "%s %s" % [amount, self.name.to_lower()]

## Rounds an amount of this asset to its innate precision.
func round(amount: float) -> float:
    return roundf(amount)

func _to_string() -> String:
    return "TradeAsset:" + self.name
