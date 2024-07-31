class_name SaveGame

## The group name used for nodes that can be saved and loaded.
const SAVEABLE_GROUP = "saveable"

## Saves all [i]saveable[/i] nodes in the scene tree to a file at the given path.
static func save(scene_tree: SceneTree, path: String) -> Error:
    var save_dict := save_tree_to_dict(scene_tree)
    var json := JSON.stringify(save_dict, "\t", false)
    var file := FileAccess.open(path, FileAccess.WRITE)
    if not file:
        return FileAccess.get_open_error()

    file.store_string(json)
    file.close()
    return OK

## Serializes all [i]saveable[/i] nodes in the scene tree to a JSON-compatible dictionary.
static func save_tree_to_dict(scene_tree: SceneTree) -> Dictionary:
    var saveable_nodes := scene_tree.get_nodes_in_group(SAVEABLE_GROUP)
    var save_dict := {}
    for node in saveable_nodes:
        var node_path := node.get_path()
        save_dict[node_path] = node.call("save_to_dict")
    
    return save_dict

## Loads saveable nodes from a file into the scene tree, merging with existing nodes.
static func load(scene_tree: SceneTree, path: String) -> Error:
    var file := FileAccess.open(path, FileAccess.READ)
    if not file:
        return FileAccess.get_open_error()
    
    var parser := JSON.new()
    var json := file.get_as_text()
    var error := parser.parse(json)
    if error != OK:
        return error
    
    var dict := parser.get_data() as Dictionary
    if not dict:
        return ERR_PARSE_ERROR
    
    load_tree_from_dict(scene_tree, dict)
    return OK

## Loads saveable nodes from a JSON dictionary into the scene tree, merging with existing nodes.
static func load_tree_from_dict(scene_tree: SceneTree, dict: Dictionary) -> void:
    for node_path: NodePath in dict:
        var existing_node := scene_tree.root.get_node_or_null(node_path)
        if existing_node == null:
            push_error("Missing nodes are not supported right now")
            continue
        
        if not existing_node.is_in_group(SAVEABLE_GROUP):
            push_warning("Loaded node ", node_path, " is not marked as saveable, refusing to load it")
            continue
        
        var save_dict: Dictionary = dict[node_path]
        existing_node.call("load_from_dict", save_dict)
