extends Node3D
class_name RadarObject

## An object to be rendered on the player's radar.
##
## Requires [signal CombatObject.targeted_by_changed] to be connected to this object.

## Declares a radar object's intentions toward the player. 
enum IFF {
    SELF,
    NEUTRAL,
    FRIENDLY,
    HOSTILE,
}

## The radar object's intentions toward the player.
@export var iff: IFF = IFF.NEUTRAL:
    set(value):
        iff = value
        self._update_iff()

## Whether this radar object is being targeted by the player.
@export var targeted: bool = false:
    set(value):
        targeted = value
        self.targeted_sprite.visible = value

## The sprite rendering the IFF status of the radar object.
@export var iff_sprite: Sprite3D

## The texture to use in the [member iff_sprite] when the object [i]is[/i] the player.
@export var texture_self: Texture2D

## The texture to use in the [member iff_sprite] when the object has neutral [member iff].
@export var texture_neutral: Texture2D

## The texture to use in the [member iff_sprite] when the object has friendly [member iff].
@export var texture_friendly: Texture2D

## The texture to use in the [member iff_sprite] when the object has hostile [member iff].
@export var texture_hostile: Texture2D

## A sprite to render when the radar object is [member targeted].
@export var targeted_sprite: Sprite3D

func _ready() -> void:
    self._update_iff()
    self.targeted_sprite.visible = self.targeted

## Replaces the active texture in the [member iff_sprite].
func _update_iff() -> void:
    match self.iff:
        IFF.SELF:
            self.iff_sprite.texture = self.texture_self
        IFF.NEUTRAL:
            self.iff_sprite.texture = self.texture_neutral
        IFF.FRIENDLY:
            self.iff_sprite.texture = self.texture_friendly
        IFF.HOSTILE:
            self.iff_sprite.texture = self.texture_hostile

func _on_targeted_by_changed(combat_object: CombatObject) -> void:
    for targeting_system in combat_object.get_targeted_by():
        if targeting_system.is_player:
            self.targeted = true
            return
    
    self.targeted = false
