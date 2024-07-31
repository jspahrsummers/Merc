extends Resource
class_name SaveableResource

## The base class for any resource that should have its current state saved into any save game files, instead of being recreated in its initial state when a game is loaded.
##
## Resources that do not inherit from SaveableResource will not be saved to disk.

func save_to_dict() -> Dictionary:
    return {}

func load_from_dict(_dict: Dictionary) -> void:
    pass
