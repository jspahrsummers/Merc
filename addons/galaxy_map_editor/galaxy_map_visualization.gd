extends Control

var galaxy: Galaxy

const MARGIN = 20
const SYSTEM_RADIUS = 5
const CONNECTION_COLOR = Color(0.5, 0.5, 0.5, 0.5)
const SYSTEM_COLOR = Color(1, 1, 1)
const FONT_COLOR = Color(1, 1, 1)

var font: Font

func _ready():
    custom_minimum_size = Vector2(400, 400)
    font = ThemeDB.fallback_font

func _enter_tree() -> void:
    self.queue_redraw()

func _draw():
    if not galaxy:
        return

    var systems = galaxy.systems
    if systems.is_empty():
        return

    var min_x = systems[0].position.x
    var max_x = systems[0].position.x
    var min_z = systems[0].position.z
    var max_z = systems[0].position.z

    for system in systems:
        min_x = min(min_x, system.position.x)
        max_x = max(max_x, system.position.x)
        min_z = min(min_z, system.position.z)
        max_z = max(max_z, system.position.z)

    var width = max_x - min_x
    var height = max_z - min_z
    var scale = min((size.x - 2 * MARGIN) / width, (size.y - 2 * MARGIN) / height)

    # Draw connections
    for system in systems:
        var from_pos = _get_draw_position(system.position, min_x, min_z, scale)
        for connection in system.connections:
            var connected_system = galaxy.get_system(connection)
            if connected_system:
                var to_pos = _get_draw_position(connected_system.position, min_x, min_z, scale)
                draw_line(from_pos, to_pos, CONNECTION_COLOR)

    # Draw systems and labels
    for system in systems:
        var pos = _get_draw_position(system.position, min_x, min_z, scale)
        draw_circle(pos, SYSTEM_RADIUS, SYSTEM_COLOR)
        draw_string(font, pos + Vector2(SYSTEM_RADIUS + 2, SYSTEM_RADIUS + 2), system.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, FONT_COLOR)

func _get_draw_position(position: Vector3, min_x: float, min_z: float, scale: float) -> Vector2:
    return Vector2(
        MARGIN + (position.x - min_x) * scale,
        MARGIN + (position.z - min_z) * scale
    )
