extends Resource
class_name TradeAsset

## Represents any asset that can be traded.

## The human-readable name for this asset.
@export var name: String

## How many pieces one unit of this asset can be subdivided into. Internal representations of amounts of this asset will be multiplied by this value.
##
## This allows us to use [int]s for computing fractional amounts of this asset, without the precision loss of floating-point math.
@export var granularity: int = 1

## Returns how much of this asset is in the [CargoHold] or [BankAccount], whichever is appropriate.
func current_amount(_cargo_hold: CargoHold, _bank_account: BankAccount) -> int:
    assert(false, "Meant to be implemented by subclasses")
    return 0

## Takes up to the specified amount of this asset from a [CargoHold] or [BankAccount], whichever is appropriate.
##
## Returns the amount actually taken, which may be less than requested if there's not enough.
func take_up_to(_amount: int, _cargo_hold: CargoHold, _bank_account: BankAccount) -> int:
    assert(false, "Meant to be implemented by subclasses")
    return 0

## Takes exactly the specified amount of this asset from a [CargoHold] or [BankAccount], whichever is appropriate.
##
## If [param allow_negative] is set [b]and[/b] this [TradeAsset] is a [Currency], the account can go into negative balance; otherwise, an attempt to take more than what's available will fail and return false.
func take_exactly(_amount: int, _cargo_hold: CargoHold, _bank_account: BankAccount, _allow_negative: bool=false) -> bool:
    assert(false, "Meant to be implemented by subclasses")
    return false

## Adds up to the specified amount of this asset to a [CargoHold] or [BankAccount], whichever is appropriate.
##
## Returns the amount actually added, which may be less than requested for commodities if there's not enough room in the cargo hold.
func add_up_to(_amount: int, _cargo_hold: CargoHold, _bank_account: BankAccount) -> int:
    assert(false, "Meant to be implemented by subclasses")
    return 0

## Adds exactly the specified amount of this asset to a [CargoHold] or [BankAccount], whichever is appropriate.
##
## If adding to a cargo hold, and there is not enough room, the operation will fail and return false.
func add_exactly(_amount: int, _cargo_hold: CargoHold, _bank_account: BankAccount) -> bool:
    assert(false, "Meant to be implemented by subclasses")
    return false

func _to_string() -> String:
    return "TradeAsset:" + self.name
