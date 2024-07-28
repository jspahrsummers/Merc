extends TradeAsset
class_name Commodity

## Represents a physical commodity that can be traded.

## The [b]in-game mass[/b] per one unit of this item, in kg.
##
## This is added to ship mass when the asset is being carried. This can also be thought of the scaling factor from "real-world metric tonne" (it usually makes sense to consider 1 unit = 1 metric tonne) to in-game kg for the physics engine.
@export var mass: float = 0.1

## The volume of one unit of this item, in cubic meters.
##
## This can be thought of as the volume per "real-world metric tonne."
@export var volume: float

## A base price for this commodity, in credits, used to compute relative prices across the galaxy and in other currencies.
@export var base_price_in_credits: float

func current_amount(cargo_hold: CargoHold, _bank_account: BankAccount) -> float:
    return cargo_hold.commodities.get(self, 0)

func take_up_to(amount: float, cargo_hold: CargoHold, _bank_account: BankAccount) -> float:
    return cargo_hold.remove_up_to(self, floori(amount))

func take_exactly(amount: float, cargo_hold: CargoHold, _bank_account: BankAccount, _allow_negative: bool=false) -> bool:
    return cargo_hold.remove_exactly(self, floori(amount))

func add_up_to(amount: float, cargo_hold: CargoHold, _bank_account: BankAccount) -> float:
    return cargo_hold.add_up_to(self, floori(amount))

func add_exactly(amount: float, cargo_hold: CargoHold, _bank_account: BankAccount) -> bool:
    return cargo_hold.add_exactly(self, floori(amount))

func _to_string() -> String:
    return "Commodity:" + self.name
