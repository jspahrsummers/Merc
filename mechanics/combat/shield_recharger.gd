extends Node3D
class_name ShieldRecharger

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
    if self.battery.power / self.battery.max_power <= self.shield.only_recharge_above:
        # Battery too low, skip recharging.
        return

    var desired_recharge := self.shield.max_integrity - self.shield.integrity
    var max_recharge := self.shield.recharge_rate * delta

    var desired_power := minf(desired_recharge, max_recharge) / self.shield.power_efficiency
    var consumed := self.battery.consume_up_to(desired_power)
    self.shield.integrity += consumed * self.shield.power_efficiency
