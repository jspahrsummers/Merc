extends Resource
class_name Hero

## A "hero" is any named NPC.
##
## These are often used as a target or escort in missions.

## The name of the hero.
@export var name: String

## Whether this hero is eligible to be targeted in bounty missions.
@export var bounty_target: bool = false

## Fires when this hero is killed in combat.
signal killed(hero: Hero)
