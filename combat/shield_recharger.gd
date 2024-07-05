extends Node

## Automatically charges a [Shield] from a [Battery] over time.

@export var battery: Battery
@export var shield: Shield

func _ready() -> void:
    var should_enable := self.battery != null \
        and self.shield != null \
        and not is_zero_approx(self.shield.recharge_rate) \
        and not is_zero_approx(self.shield.power_efficiency)

    self.set_physics_process(should_enable)

func _physics_process(delta: float) -> void:
    var desired_power := self.shield.recharge_rate / self.shield.power_efficiency * delta
    var consumed := self.battery.consume_up_to(desired_power)
    self.shield.integrity += consumed * self.shield.power_efficiency
