# Contributing

At the moment, this is basically just a personal project, so I'm not looking for contributions. But if you're interested in contributing nonetheless, read on!

## Content creation

Good games benefit from a lot of content! Expanding the content of the game can even be more impactful than code contributions. Here are some ways to contribute more content to the game.

_Note:_ you will need the [Godot engine](https://godotengine.org) to add content, even if you're not making code changes.

### Star systems

To introduce a new star system:

1. Create a [`StarSystem`](galaxy/star_system/star_system.gd) resource in [galaxy/star_system/star_systems/](galaxy/star_system/star_systems/), and fill in its properties, using the documentation shown in the editor as a guide.
2. For any star system you have listed as a `connection` of your _new_ system, you must also open up _their_ `StarSystem` resources, and add your new system as a `connection` of them, so they are connected bidirectionally.
3. Create a new scene in [galaxy/star_system/scenes/](galaxy/star_system/scenes/) with a root type of [`StarSystemInstance`](galaxy/star_system/star_system_instance.gd), and connect its `star_system` property back to the `StarSystem` resource you created in step 1.
4. Set the `scene_path` property of your `StarSystem` resource to the file path of the new scene.

Your new scene file is now the canvas upon which to create your star system! You can add the following types of entities into your scene to populate the system. All of them can be moved around and rotated as you see fit.

#### Planets

Add planets to your system by instantiating the `planet_instance.tscn` scene. To customize the planet's appearance (sprite) or other properties, right-click the planet instance in the scene tree and enable "Editable Children."

If you want the player to be able to land on your new planet, create a [`Port`](galaxy/port/port.gd) resource in [galaxy/port/ports/](galaxy/port/ports/), and set the `port` property of the `PlanetInstance` to the new resource. Add the `Port` resource to the `ports` array of the `StarSystem` as well.

Then, fill in the `Port` properties, especially the landscape image and the description that the player will see when they land. (You can also [use AI to help here](./README.md#use-of-ai)!)

#### Stars

Stars of all kinds can be added by instantiating any of the scenes in [galaxy/stars/](galaxy/stars/).

To define a new type of star, create a new inherited scene from `base_star.tscn` specifically, which is the base of all the others. Note that we shouldn't need to define _that_ many unique types of stars.

#### Non-player ships

The most basic way to add a ship to the scene is to just instantiate the scene of the specific ship type that you want (e.g., `corvette01.tscn`, `freighter.tscn`, `frigate03.tscn`). This will create a ship with no attached AI behaviors, so it will just sit there. To introduce behaviors, right-click and enable "Editable Children," then add a child node that does what you want—for example:
* Instantiate `pirate.tscn` to turn it into a pirate ship that will attack the player and other ships.
* Add an [`AINavigation`](actors/ai/ai_navigation.gd) node to make the ship navigate toward a particular location, without engaging in combat.

To instead introduce ships that have behaviors already defined, instantiate any of the templates in [actors/ai/](actors/ai/) (e.g., `pirate_frigate`).

## Code

All Godot scripting in this project uses [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html). Please follow these conventions when writing new code:
* Everything should have static typing, to the extent possible.
* All private variables and methods (those not meant to be visible to the editor or callers) should be prefixed with an underscore.
* No implicit `self`. Calls to methods or properties on the same instance should always explicitly start with `self.` This makes it clearer to readers of the code what is happening.
* Use methods that give you static types instead of those that just use `StringName`s. For example:
    * Prefer `self.some_signal.emit()` over `self.emit_signal("some_signal")`
    * Prefer `self.some_method.call_deferred()` over `self.call_deferred("some_method")`
* Prefer declaring properties with `@export` and connecting them in the editor, over using `@onready` with `NodePath`s, `get_node()`, etc.

### In-game AI

It's always great to have additional AI options for [non-player ships](#non-player-ships)! You can find the existing implementations in [actors/ai/](actors/ai/), to use as a jumping-off point for implementing new behaviors.

_Note:_ if multiple [actor](actors/) implementations start to have a lot in common, it's a sign that we should probably factor out additional types of [mechanics](mechanics/) that can be shared between them.

### Saving and Loading Games

The game uses a custom saving and loading system implemented via the `SaveGame` autoload class. To add new saveable data to the game, follow these steps:

1. Any node that needs to be saved should be added to the `saveable` group.
1. Saveable nodes must implement at least two methods:
    * `save_to_dict()`: Returns a dictionary containing the node's saveable state.
    * `load_from_dict(dict: Dictionary)`: Loads the node's state from the given dictionary.
    * There are also `before_save()`, `after_save()`, `before_load()`, and `after_load()` methods that can be implemented to perform additional logic.
1. Resources with any state to be saved should extend `SaveableResource`. This is usually enough to ensure that the resource is saved and loaded correctly, but there are `save_to_dict()` and `load_from_dict()` methods that can be overridden if necessary.

Remember to test saving and loading thoroughly when making changes to ensure that all game state is properly preserved.
