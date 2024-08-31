# Merc

Embark on an interstellar journey in Merc, a fresh addition to the beloved lineage of space trading and combat games like [Escape Velocity](https://en.wikipedia.org/wiki/Escape_Velocity_(video_game)) and [Endless Sky](https://endless-sky.github.io/). Pilot your ship through a vast galaxy, forge a career as a trader or take on contracts as a skilled freelancer, and engage in thrilling space battles—all rendered in full 3D while maintaining the top-down gameplay of the games that inspired Merc.

### Key Features

- **2.5D gameplay**: Experience the best of both worlds with top-down space exploration and combat, powered by a full 3D engine for enhanced visuals and effects.
- **Immersive visuals**: Enjoy detailed 3D models, particle effects, and scenic backgrounds that bring the space frontier to life.
- **Deep economy**: Navigate a complex economic system, including multiple currencies across the galaxy. Engage in commodity and currency trading to maximize your profits as you voyage between star systems.
- **Diverse mission types**: Take on a variety of missions, from simple cargo runs to challenging bounty hunts.
- **Dynamic combat**: Face off against pirates and other threats in fast-paced, skill-based space battles.
- _(Coming soon)_ **Ship customization**: Upgrade and outfit your vessel with various weapons, shields, and other systems to suit your playstyle.
- _(Coming soon)_ **A more expansive galaxy**: Explore a massive galaxy filled with unique star systems, each with its own characteristics, markets, and opportunities.

Whether you're a veteran space trader or new to the genre, Merc offers a fresh experience that combines nostalgic gameplay with modern graphics and innovative features.

Chart your own course through the stars—will you become a wealthy merchant, a fearsome pirate, or a celebrated hero? It's up to you!

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

Some of the code is authored with the help of [Claude](https://claude.ai), which is pretty good at writing [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html). Claude is also a great writing and content creation assistant! The included [claude.py](script/claude.py) script can be used to automatically load the project into Claude to make changes.

[Midjourney](https://www.midjourney.com) is used to generate some of the imagery for the game, particularly where there don't seem to be any comparably good assets available (for free or for a reasonable price) from other sources.
