extends Resource
class_name Currency

## Represents a currency that can be used to pay for goods and services.

## The human-readable name for this currency.
@export var name: String

func _to_string() -> String:
    return "Currency:" + self.name
