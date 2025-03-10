# Claude Guidelines for Merc

## Project Overview
Merc is an Escape Velocity-like space trading and combat game built with Godot
4.4 and GDScript. You should help with designing the game's mechanics, crafting
story and game content, as well as programming behaviors into the game itself.

## Content Creation
When designing new star systems and ports, keep the following in mind:
- There can only be one trading market for a whole star system. All ports within
the system share the same trading market (meaning the same list of commodities
and prices).
- Planetary descriptions should be interesting and captivating, but limit them
to approximately five or so paragraphs.

## Code Style Guidelines
- Use static typing throughout GDScript files
- Prefix private variables/methods with underscore (_)
- Always use explicit `self.` to reference instance variables/methods
- Prefer methods that provide static types over StringName
- Use `@export` for properties connected in editor over `@onready` with NodePath
- Follow existing naming conventions: snake_case for variables and functions, PascalCase for classes
- For saveable objects: implement `save_to_dict()` and `load_from_dict(dict)` methods
- Resources with state should extend `SaveableResource`
- Add saveable nodes to the "saveable" group