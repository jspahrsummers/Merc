extends TradeAsset
class_name Currency

## Represents a digital currency that can be used to pay for goods and services.

func _to_string() -> String:
    return "Currency:" + self.name
