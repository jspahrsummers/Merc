@tool
extends Control

var galaxy: Galaxy
var dragging_system: StarSystem = null
var creating_connection: StarSystem = null

var _default_font := ThemeDB.fallback_font

const SCALE = 20

func _ready():
    galaxy = load("res://galaxy/main_galaxy.tres")
    update_galaxy_view()

func _draw():
    self.draw_set_transform(self.size / 2, 0, Vector2(2.0, 2.0))

    # Draw connections
    for system in galaxy.systems:
        for connection in system.connections:
            var connected_system = galaxy.get_system(connection)
            draw_line(Vector2(system.position.x, system.position.z) * SCALE, Vector2(connected_system.position.x, connected_system.position.z) * SCALE, Color.WHITE)

    # Draw systems
    for system in galaxy.systems:
        draw_string(self._default_font, Vector2(system.position.x, system.position.z) * SCALE, system.name, HORIZONTAL_ALIGNMENT_CENTER)

func _gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                var clicked_system = get_system_at_position(event.position)
                if clicked_system:
                    if creating_connection:
                        add_connection(creating_connection, clicked_system)
                        creating_connection = null
                    else:
                        dragging_system = clicked_system
                else:
                    add_new_system(event.position)
            else:
                dragging_system = null
        elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
            var clicked_system = get_system_at_position(event.position)
            if clicked_system:
                creating_connection = clicked_system

    elif event is InputEventMouseMotion:
        if dragging_system:
            dragging_system.position = event.position
            update_galaxy_view()

func get_system_at_position(position: Vector2) -> StarSystem:
    for system in galaxy.systems:
        if position.distance_to(Vector2(system.position.x, system.position.z)) < 10:
            return system
    return null

func add_new_system(position: Vector2):
    var new_system = StarSystem.new()
    new_system.name = "New System"
    new_system.position = position
    galaxy.systems.append(new_system)
    update_galaxy_view()

func add_connection(from_system: StarSystem, to_system: StarSystem):
    if not to_system.name in from_system.connections:
        from_system.connections.append(to_system.name)
    if not from_system.name in to_system.connections:
        to_system.connections.append(from_system.name)
    update_galaxy_view()

func update_galaxy_view():
    ResourceSaver.save(galaxy, "res://galaxy/main_galaxy.tres")
    queue_redraw()
