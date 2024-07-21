extends Control

var star_system: StarSystem

const SCALE = 20

func _draw() -> void:
    self.draw_set_transform(self.size / 2)

    # Current system
    self.draw_circle(Vector2.ZERO, 5, Color.WHITE)

    var galaxy: Galaxy = star_system.galaxy.get_ref()
    for connection in self.star_system.connections:
        var connected_system := galaxy.get_system(connection)
        var connected_position := connected_system.position - self.star_system.position

        self.draw_circle(Vector2(connected_position.x, connected_position.z) * SCALE, 5, Color.WHITE)
        self.draw_line(Vector2(0, 0), Vector2(connected_position.x, connected_position.z) * SCALE, Color.WHITE)
