extends Node3D
class_name Radiator

## Radiates heat away from a [HeatSink] into vacuum.

## How much heat is radiated away per second.
@export var rate: float

var heat_sink: HeatSink

func _physics_process(delta: float) -> void:
    self.heat_sink.heat -= self.rate * delta
