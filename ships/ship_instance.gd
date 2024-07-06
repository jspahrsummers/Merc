extends RigidBody3D

@export var ship: Ship
@export var combat_object: CombatObject
@export var targeting_system: TargetingSystem
@export var rigid_body_thruster: RigidBodyThruster
@export var rigid_body_direction: RigidBodyDirection
@export var rigid_body_turner: RigidBodyTurner
@export var power_management_unit: PowerManagementUnit
@export var radar_object: RadarObject
@export var weapon_mounts: Array[WeaponMount]
@export var shield_recharger: ShieldRecharger

func _ready() -> void:
    pass
    # self.ship = self.ship.duplicate()
    # self.mass = self.ship.physics_properties.mass
    # self.combat_object.hull = self.ship.hull
    # self.combat_object.shield = self.ship.shield
    # self.rigid_body_thruster.thruster = self.ship.thruster
    # self.rigid_body_thruster.battery = self.ship.battery
