extends Resource
class_name Ship

## Represents a ship's physics and gameplay features.

@export var physics_properties: PhysicsProperties
@export var hull: Hull
@export var shield: Shield
@export var thruster: Thruster
@export var spin_thruster: SpinThruster
@export var battery: Battery
@export var power_generator: PowerGenerator
@export var weapons: Array[Weapon]

## When arriving from a hyperspace jump, the ship's position will be randomized around the system center. This is the maximum radius (in m) that the randomized position is allowed to occupy.
# TODO: Move this somewhere better.
@export var hyperspace_arrival_radius: float

func _get_property_list() -> Array[Dictionary]:
    return [
        {
            "name": "hull",
            "class_name": &"Hull",
            "type": TYPE_OBJECT,
            "hint": PROPERTY_HINT_NONE,
            "hint_stages": "",
            "usage": PROPERTY_USAGE_SCRIPT_VARIABLE|PROPERTY_USAGE_ALWAYS_DUPLICATE
        },
        {
            "name": "shield",
            "class_name": &"Shield",
            "type": TYPE_OBJECT,
            "hint": PROPERTY_HINT_NONE,
            "hint_stages": "",
            "usage": PROPERTY_USAGE_SCRIPT_VARIABLE|PROPERTY_USAGE_ALWAYS_DUPLICATE
        },
        {
            "name": "battery",
            "class_name": &"Battery",
            "type": TYPE_OBJECT,
            "hint": PROPERTY_HINT_NONE,
            "hint_stages": "",
            "usage": PROPERTY_USAGE_SCRIPT_VARIABLE|PROPERTY_USAGE_ALWAYS_DUPLICATE
        },
    ]
