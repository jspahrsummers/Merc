extends Resource
class_name Hero

## A "hero" is any named NPC.
##
## These are often used as a target or escort in missions.

## The name of the hero.
@export var name: String

const _BOUNTIES_DIRECTORY = "res://actors/heroes/bounties/"

## Randomly picks a hero that is eligible to have a bounty.
static func pick_random_bounty() -> Hero:
    var files := DirAccess.get_files_at(_BOUNTIES_DIRECTORY)
    var random_file := files[randi_range(0, files.size() - 1)]
    return load("%s/%s" % [_BOUNTIES_DIRECTORY, random_file])
