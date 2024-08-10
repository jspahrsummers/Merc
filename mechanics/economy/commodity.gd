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

## The maximum percentage the price can deviate from the base price for cheap commodities.
const MAX_PRICE_DEVIATION_CHEAP = 0.5

## The maximum percentage the price can deviate from the base price for expensive commodities.
const MAX_PRICE_DEVIATION_EXPENSIVE = 0.2

## The price threshold for considering a commodity "expensive".
const EXPENSIVE_THRESHOLD = 5000.0

const _SPECIAL_COMMODITIES_DIRECTORY = "res://mechanics/economy/commodities/specials/"

## Calculates the actual price, in credits, based on a relative price between 0 and 1.
func price_in_credits(relative_price: float) -> float:
    return MathUtils.relative_to_absolute_price(relative_price, self.base_price_in_credits, self._max_deviation())

## Calculates the maximum price deviation based on the commodity's base price.
func _max_deviation() -> float:
    var t := minf(self.base_price_in_credits / EXPENSIVE_THRESHOLD, 1.0)
    return lerp(MAX_PRICE_DEVIATION_CHEAP, MAX_PRICE_DEVIATION_EXPENSIVE, t)

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

func price_converted_from_credits(price: float) -> float:
    # TODO: This exchange rate mechanism probably isn't thought-out enough…
    return roundf(price / self.base_price_in_credits)

func _to_string() -> String:
    return "Commodity:" + self.name

## Randomly picks one of the special commodities.
static func pick_random_special() -> Commodity:
    var files := DirAccess.get_files_at(_SPECIAL_COMMODITIES_DIRECTORY)
    var random_file := files[randi_range(0, files.size())]
    return load("%s/%s" % [_SPECIAL_COMMODITIES_DIRECTORY, random_file])
