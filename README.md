# Merc

Merc is a top-down (2.5D) space sim inspired by the [Escape Velocity](https://en.wikipedia.org/wiki/Escape_Velocity_(video_game)) series of computer games, and more recently [Endless Sky](https://endless-sky.github.io/).

Instructions:

* Arrow keys to maneuver
* Tab to target ships
* Space to fire
* M to view the galaxy map
* H to select a hyperspace jump destination
* J to jump to hyperspace
* ` (backtick) or § to select a planet to land on
* L to land
* C to open the currency trading window
* Scroll wheel to zoom in and out

## Development

Merc is built using the [Godot](https://godotengine.org/) game engine.

To view or develop the project:
1. [Download](https://godotengine.org/download/) Godot. Match the version specified in the [main build workflow](.github/workflows/main.yml) for best results.
1. Clone the repository to your machine.
1. Open Godot, and import the repository folder.

Code for the game is written in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html), Godot's primary scripting language.

### Deployment

Commits or merges into the `main` branch will automatically build a new release for all supported platforms, and [publish to itch.io](https://jspahrsummers.itch.io/merc). macOS builds on CI also include code signing and [notarization](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/).

## Use of AI

Some of the code is authored with the help of [Claude](https://claude.ai), which is surprisingly capable of writing [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html). Try setting up a [project](https://claude.ai/projects), then uploading this README and the most relevant source files, and you'll be able to ask it to author full, working scripts!

[Midjourney](https://www.midjourney.com) is used to generate some of the imagery for the game, particularly where there don't seem to be any comparably good assets available (for free or for a reasonable price) from other sources.
