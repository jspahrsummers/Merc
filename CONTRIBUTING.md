# Contributing

At the moment, this is basically just a personal project, so I'm not looking for contributions. But if you're interested in contributing nonetheless, read on!

## Content creation

Good games benefit from a lot of content! Expanding the content of the game can even be more impactful than code contributions. Here are some ways to contribute more content to the game.

_Note:_ you will need the [Godot engine](https://godotengine.org) to add content, even if you're not making code changes.

### Star systems

To introduce a new star system:

1. Create a [`StarSystem`](galaxy/star_system/star_system.gd) resource in [galaxy/star_system/star_systems/](galaxy/star_system/star_systems/), and fill in its properties, using the documentation shown in the editor as a guide.
2. For any star system you have listed as a `connection` of your _new_ system, you must also open up _their_ `StarSystem` resources, and add your new system as a `connection` of them, so they are connected bidirectionally.
3. Add your system to `main_galaxy.tres`, the main [`Galaxy`](galaxy/galaxy.gd) resource. This ensures that your new system will properly show up in the galaxy map.
4. Create a new scene in [galaxy/star_system/scenes/](galaxy/star_system/scenes/) for your star system, and make sure to set the `scene_path` property of your `StarSystem` resource to the file path to the new scene.
5. In your new scene, attach the [`StarSystemInstance`](galaxy/star_system/star_system_instance.gd) script to the root node, and fill in its properties.

Your new scene file is now the canvas upon which to create your star system! You can add the following types of entities into your scene to populate the system. All of them can be moved around and rotated as you see fit.

#### Planets

Add planets to your system by instantiating the `planet_instance.tscn` scene. To customize the planet's appearance (sprite) or other properties, right-click the planet instance in the scene tree and enable "Editable Children."

If you want the player to be able to land on your new planet, create a [`Planet`](planet/planet.gd) resource in [planet/planets/](planet/planets/), and set the `planet` property of the `PlanetInstance` to the new resource. Then, fill in the `Planet` properties, especially the landscape image and the description that the player will see when they land. (You can also [use AI to help here](./README.md#use-of-ai)!)

#### Stars

Stars of all kinds can be added by instantiating any of the scenes in [stars/](stars/).

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
