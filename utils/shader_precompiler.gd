extends SubViewport

## Hacky way to precompile shaders and avoid hiccups when instantiating objects later.
##
## The listed scenes are prerendered to an offscreen texture, forcing shaders to be
## compiled and everything loaded into memory. For some reason, this still doesn't
## cut out _all_ of the hiccup later, but at least reduces it meaningfully.

## Scenes to prerender.
@export var precompile: Array[PackedScene] = []

func _ready() -> void:
    self.get_texture()

    for scene in self.precompile:
        var node := scene.instantiate()
        self.add_child(node)

    await RenderingServer.frame_post_draw
    self.queue_free()
