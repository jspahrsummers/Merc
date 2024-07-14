extends Node3D
class_name StarSystemInstance

## Instantiates a star system.

@export var star_system: StarSystem

## Walks the ancestors of [param node] and finds the first [StarSystemInstance] (i.e., the one containing the node).
static func star_system_instance_for_node(node: Node) -> StarSystemInstance:
    while not (node is StarSystemInstance):
        node = node.get_parent()
        if node == null:
            return null
    
    return node
