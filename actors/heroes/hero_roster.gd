extends Node3D
class_name HeroRoster

## Maintains a list of [Hero]s that are alive in the game.

## Current heroes.
##
## NOTE: This array must not be mutated at runtime from outside this class!
@export var heroes: Array[Hero] = []:
    set(value):
        if value == heroes:
            return

        self._unsubscribe_from_heroes()
        heroes = value.duplicate()
        self._subscribe_to_heroes()

func _subscribe_to_heroes() -> void:
    for hero in self.heroes:
        hero.killed.connect(_on_hero_killed)

func _unsubscribe_from_heroes() -> void:
    for hero in self.heroes:
        hero.killed.disconnect(_on_hero_killed)

func _on_hero_killed(hero: Hero) -> void:
    self.heroes.erase(hero)

## Randomly picks a hero that is eligible to have a bounty, or returns null if none are available.
func pick_random_bounty() -> Hero:
    var eligible := self.heroes.filter(func(hero: Hero) -> bool: return hero.bounty_target)
    if not eligible:
        return null

    return eligible.pick_random()

## See [SaveGame].
func save_to_dict() -> Dictionary:
    var result := {}
    result["heroes"] = SaveGame.serialize_array_of_resources(self.heroes)
    return result

## See [SaveGame].
func load_from_dict(dict: Dictionary) -> void:
    var heroes_array: Array = dict["heroes"]
    self.heroes = SaveGame.deserialize_array_of_resources(heroes_array)
