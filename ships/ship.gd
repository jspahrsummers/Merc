extends RigidBody3D
class_name Ship

## Represents a ship currently in play.
##
## Subclasses implement player or AI controls, although a derelict ship can be represented by this class alone.

## The definition of this ship's type.
@export var ship_def: ShipDef

## A scene to instantiate when the ship fires its weapon.
@export var bullet: PackedScene

## A scene to instantiate when the ship is destroyed.
@export var explosion: PackedScene

## An audio clip to play while the ship's thrusters are active.
##
## This audio stream should be a looping sound. Rather than restarting from the beginning each time the thruster is used, the audio stream is paused and resumed, and evenutally loops.
@export var thruster_audio: AudioStreamPlayer3D

## This ship's mesh.
@export var mesh_instance: MeshInstance3D

@export var target_overlay: Node3D

## This ship's minimap icon.
@export var minimap_mesh_instance: MeshInstance3D

## A material to override this ship's minimap icon when it is targeted by the player.
@export var minimap_target_override_material: BaseMaterial3D

## Whether the ship node should be removed from the scene tree and freed when it is destroyed.
##
## If false, the ship will instead be made invisible and stop participating in physics and collision calculations. This is mostly useful for the player's ship, which is often expected to exist (even if invisible) by other nodes.
@export var free_when_destroyed: bool = true

## Physical attachments on the ship from which weapons fire.
##
## Indices correspond 1:1 to [member ShipDef.weapons].
@export var weapon_hardpoints: Array[Node3D] = []

## Engine glow geometry, which will be animated between 0 and 1 transparency depending on thrust.
@export var engine_glow: Array[GeometryInstance3D] = []

## How long the engine glow should take to fade in or out.
@export var engine_glow_tween_duration_sec: float = 0.4

@export var shield_effect: MeshInstance3D
@export var shield_effect_duration_sec: float = 0.4

## Fires when this ship's hull integrity changes (e.g., due to damage).
signal ship_hull_changed(ship: Ship)

## Fires when this ship's shield strength changes (e.g., due to damage).
signal ship_shield_changed(ship: Ship)

## Fires when this ship's energy level changes.
signal ship_energy_changed(ship: Ship)

## Fires when this ship is destroyed, before the node is freed.
signal ship_destroyed(ship: Ship)

## Fires when this ship changes its target.
signal ship_target_changed(ship: Ship, targeted_ship: Ship)

## The ship's current hull integrity.
##
## This property should not be written to outside the class!
var hull: float

## The ship's current shield strength.
##
## This property should not be written to outside the class!
var shield: float

## The ship's current energy level.
##
## This property should not be written to outside the class!
var energy: float

## The ship's current target.
##
## This property should not be written to outside the class!
var target: Ship = null

## The last tick (in ms) when the ship fired each weapon.
var _last_fired_msec: Array[int]

## Any in-flight engine glow tweening.
var _engine_glow_tween: Tween

## The target transparency for the current engine glow animation.
##
## Can be used to selectively replace the existing tween if it's not animating to the desired value already.
var _engine_glow_transparency: float = 1.0

var _shield_tween: Tween

func _ready() -> void:
    self.mass = self.ship_def.mass_kg

    self.hull = self.ship_def.hull
    assert(self.hull > 0, "Hull must be greater than 0")

    self.shield = self.ship_def.shield
    self.energy = self.ship_def.energy

    self.emit_signal("ship_hull_changed", self)
    self.emit_signal("ship_shield_changed", self)
    self.emit_signal("ship_energy_changed", self)

    for node in self.engine_glow:
        node.transparency = 1.0
    
    self.shield_effect.transparency = 1.0
    self.target_overlay.global_rotation = Vector3.ZERO

    _last_fired_msec.resize(self.ship_def.weapons.size())

## Damage this ship by the [code]shield[/code] and [code]hull[/code] amounts specified in the given dictionary.
##
## If the ship has shields up, damage is applied to the shields first, then the hull, in proportion.
func damage(dmg: Dictionary) -> void:
    var hull_dmg: float = dmg.get("hull", 0.0)
    var shield_dmg: float = dmg.get("shield", 0.0)
    var apply_hull_dmg_pct := 1.0

    if self.shield > 0.01: # compare with epilson to mitigate floating point rounding issues
        assert(self.hull > 0.0, "Hull must be greater than 0 if shield is up")

        self._show_shields()

        var actual_shield_dmg := minf(self.shield, shield_dmg)
        self.shield -= actual_shield_dmg
        self.emit_signal("ship_shield_changed", self)

        # Reduce hull damage proportionally to the shield damage applied
        apply_hull_dmg_pct -= actual_shield_dmg / shield_dmg
    
    if apply_hull_dmg_pct > 0.0:
        self.hull -= hull_dmg * apply_hull_dmg_pct
        self.emit_signal("ship_hull_changed", self)

    if self.hull <= 0.01: # compare with epilson to mitigate floating point rounding issues
        self._explode()

func _show_shields() -> void:
    if self._shield_tween != null:
        self._shield_tween.kill()

    var tween := self.create_tween()
    tween.tween_property(self.shield_effect, "transparency", 0.0, self.shield_effect_duration_sec / 2.0)
    tween.tween_property(self.shield_effect, "transparency", 1.0, self.shield_effect_duration_sec / 2.0)
    
    self._shield_tween = tween

## Attempt to fire the ship's weapons.
##
## This will silently fail if no weapons are available to fire, or the ship lacks energy to fire any of them.
func fire() -> void:
    for idx in range(self.ship_def.weapons.size()):
        self._fire_weapon(idx)

func _fire_weapon(idx: int) -> void:
    var weapon := self.ship_def.weapons[idx]
    var hardpoint := self.weapon_hardpoints[idx]

    var now := Time.get_ticks_msec()
    if now - self._last_fired_msec[idx] < weapon.fire_interval_msec:
        return
    
    if self.energy < weapon.energy_consumption:
        return
    
    self.energy -= weapon.energy_consumption
    self.emit_signal("ship_energy_changed", self)

    var bullet_instance: RigidBody3D = self.bullet.instantiate()
    get_parent().add_child(bullet_instance)
    bullet_instance.add_collision_exception_with(self)
    bullet_instance.global_transform = hardpoint.global_transform

    bullet_instance.linear_velocity = self.linear_velocity
    bullet_instance.apply_central_impulse(bullet_instance.transform.basis * weapon.fire_force * Vector3.FORWARD)

    self._last_fired_msec[idx] = now

## Destroys the ship.
func _explode() -> void:
    var explosion_instance: AnimatedSprite3D = self.explosion.instantiate()
    self.get_parent().add_child(explosion_instance)
    explosion_instance.global_transform = self.global_transform

    self.emit_signal("ship_destroyed", self)
    if self.free_when_destroyed:
        self.queue_free()
    else:
        self.visible = false
        self.freeze = true
        self.collision_mask = 0
        self.collision_layer = 0

## Invoked by subclasses to apply a thrust force to the ship.
##
## This is expected to be invoked during a physics step (i.e., [code]_physics_process[/code]) and not otherwise.
func thrust_step(magnitude: float, step_delta: float) -> void:
    if is_zero_approx(self.energy):
        self.thrust_stopped()
        return
    
    self._tween_engine_glow_transparency(1.0 - magnitude)

    if self.thruster_audio.stream_paused:
        self.thruster_audio.stream_paused = false
    if !self.thruster_audio.playing:
        self.thruster_audio.play()

    var desired_energy := self.ship_def.thrust_energy_consumption * magnitude * step_delta
    var energy_consumed := minf(self.energy, desired_energy)
    self.energy -= energy_consumed
    self.apply_central_force(self.transform.basis * Vector3.FORWARD * self.ship_def.thrust * magnitude * (energy_consumed / desired_energy))
    self.emit_signal("ship_energy_changed", self)

## Invoked by subclasses on physics steps where no thrust should be applied.
func thrust_stopped() -> void:
    self.thruster_audio.stream_paused = true
    self._tween_engine_glow_transparency(1.0)

func _tween_engine_glow_transparency(to_transparency: float) -> void:
    if is_equal_approx(self._engine_glow_transparency, to_transparency):
        return

    if self._engine_glow_tween != null:
        self._engine_glow_tween.kill()

    var tween := self.create_tween()
    tween.set_parallel(true)
    for node in self.engine_glow:
        tween.tween_property(node, "transparency", to_transparency, self.engine_glow_tween_duration_sec)
    
    self._engine_glow_tween = tween
    self._engine_glow_transparency = to_transparency

## Sets the ship's target.
##
## This must be used instead of changing the [member target] property, to correctly connect and fire signals.
func set_target(targeted_ship: Ship) -> void:
    if targeted_ship == self.target:
        return

    if self.target != null:
        self.target.ship_destroyed.disconnect(_on_ship_destroyed)

    self.target = targeted_ship
    if targeted_ship != null:
        targeted_ship.ship_destroyed.connect(_on_ship_destroyed)

    self.emit_signal("ship_target_changed", self, targeted_ship)

## Invoked when the player's target changes to or from this ship, to apply or remove the corresponding visual indicator.
func set_targeted_by_player(targeted: bool) -> void:
    if targeted:
        self.target_overlay.visible = true
        self.minimap_mesh_instance.material_override = self.minimap_target_override_material
    else:
        self.target_overlay.visible = false
        self.minimap_mesh_instance.material_override = null

func _on_ship_destroyed(ship: Ship) -> void:
    assert(ship == self.target, "Should only receive ship destruction notification from current target")
    self.set_target(null)

func _process(_delta: float) -> void:
    self.target_overlay.global_position = self.global_position

func _physics_process(delta: float) -> void:
    # Recharge energy first, so that it can be used to replenish shields if available.
    self._recharge_energy(delta)
    self._recharge_shield(delta)

func _recharge_energy(delta: float) -> void:
    if self.freeze or is_zero_approx(self.ship_def.energy_recharge_rate) or is_equal_approx(self.energy, self.ship_def.energy):
        return

    self.energy = minf(self.energy + self.ship_def.energy_recharge_rate * delta, self.ship_def.energy)
    self.emit_signal("ship_energy_changed", self)

func _recharge_shield(delta: float) -> void:
    if self.freeze or is_zero_approx(self.ship_def.shield_recharge_rate) or is_equal_approx(self.shield, self.ship_def.shield):
        return
    
    var recharge := self.ship_def.shield_recharge_rate * delta
    if self.energy < recharge:
        return

    self.shield = minf(self.shield + recharge, self.ship_def.shield)
    self.energy -= recharge
    
    self.emit_signal("ship_shield_changed", self)
    self.emit_signal("ship_energy_changed", self)

## Attempts to consume energy for incremental turning. Returns false if there is no energy available.
func consume_turning_energy(delta: float) -> bool:
    if is_zero_approx(self.energy):
        return false
    
    self.energy = maxf(0, self.energy - self.ship_def.turning_energy_consumption * delta)
    self.emit_signal("ship_energy_changed", self)
    return true
