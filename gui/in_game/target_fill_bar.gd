extends Control
class_name TargetFillBar

@export var max_value: float:
    get:
        return self._max_value
    set(value):
        self._max_value = value
        self._update()

@export var value: float:
    get:
        return self._value
    set(value):
        self._value = value
        self._update()

@export var fill_rect: NinePatchRect

@export var max_width: float
@export var min_width: float

var _max_value: float
var _value: float

func _ready() -> void:
    self._update()

func _update() -> void:
    if self.fill_rect == null:
        return

    var percentage := 0.0 if is_zero_approx(self.max_value) else clampf(self.value / self.max_value, 0.0, 1.0)

    self.fill_rect.visible = not is_zero_approx(percentage)
    self.fill_rect.size.x = (self.max_width - self.min_width) * percentage + self.min_width
