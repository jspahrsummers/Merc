class_name NodeUtils

## Returns the [NodePath] to the parent of the given node path.
static func get_parent_path(node_path: NodePath) -> NodePath:
    var array := PackedStringArray()
    array.resize(node_path.get_name_count() - 1)
    for i in range(array.size()):
        array.set(i, node_path.get_name(i))
    
    return NodePath("/"+"/".join(array))
