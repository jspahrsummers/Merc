extends MeshInstance3D

## Performs the visual effect accompanying a hyperspace jump.
##
## Besides being visually interesting, this effect also serves to hide the scene transition, where otherwise nodes would pop in and out.

@export var hyperspace_controller: HyperspaceController
@export var hyperspace_viewport: SubViewport

## An audio clip to play when a hyperspace jump begins.
@export var jump_out_audio: AudioStreamPlayer

## The rotation the mesh should have at the start and end of a jump.
@export var initial_rotation := Vector3.ZERO

## The scale the mesh should have at the start and end of a jump.
@export var initial_scale := Vector3.ZERO

## The scale that the mesh should animate to at the peak of the jump.
@export var jump_out_scale := Vector3.ONE * 2.7

## The total duration (in s) of the jump effect, including jumping out and jumping in.
@export var total_jump_duration_sec := 3.0

func _random_radians() -> float:
    return randf_range(0, 2 * PI)

func _random_rotation() -> Vector3:
    return Vector3(
        _random_radians(),
        _random_radians(),
        _random_radians(),
    )

func _on_jump_started(_destination: StarSystem) -> void:
    self.hyperspace_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    self.rotation = self.initial_rotation
    self.scale = self.initial_scale
    self.visible = true

    # Jump out effect
    var tween := self.create_tween()
    tween.tween_property(self, "rotation", _random_rotation(), self.total_jump_duration_sec / 2)
    tween.parallel().tween_property(self, "scale", self.jump_out_scale, self.total_jump_duration_sec / 2)

    jump_out_audio.play()

    await tween.finished

    self.hyperspace_controller.load_jump_destination()

    # Jump in effect
    tween = self.create_tween()
    tween.tween_property(self, "rotation", self.initial_rotation, self.total_jump_duration_sec / 2)
    tween.parallel().tween_property(self, "scale", self.initial_scale, self.total_jump_duration_sec / 2)

    await tween.finished

    self.visible = false
    self.hyperspace_controller.finish_jump()
