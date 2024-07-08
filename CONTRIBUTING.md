# Contributing

At the moment, this is basically just a personal project, so I'm not looking for contributions. But if you're interested in contributing, feel free to reach out to me and we can discuss it.

## Coding conventions

All Godot scripting in this project uses [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html), following these conventions:
* Everything should have static typing, to the extent possible.
* All private variables and methods (those not meant to be visible to the editor or callers) should be prefixed with an underscore.
* No implicit `self`. Calls to methods or properties on the same instance should always explicitly start with `self.` This makes it clearer to readers of the code what is happening.
* Use methods that give you static types instead of those that just use `StringName`s. For example:
    * Prefer `self.some_signal.emit()` over `self.emit_signal("some_signal")`
    * Prefer `self.some_method.call_deferred()` over `self.call_deferred("some_method")`
* Prefer declaring properties with `@export` and connecting them in the editor, over using `@onready` with `NodePath`s, `get_node()`, etc.
