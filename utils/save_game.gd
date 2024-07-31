class_name SaveGame

## The group name used for nodes that can be saved and loaded.
const SAVEABLE_GROUP = "saveable"

## A private key used to store a node's [member Node.scene_file_path] when saving.
const _SCENE_FILE_PATH_KEY = "__scene_file_path"

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
        var node_dict := {_SCENE_FILE_PATH_KEY: node.scene_file_path}
        node_dict.merge(node.call("save_to_dict") as Dictionary)
        save_dict[node_path] = node_dict
    
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
    var node_paths: Array[NodePath] = []
    dict.keys().assign(node_paths)

    # Load nodes in order of depth, to ensure parents are loaded before children.
    # We'll use this to instantiate any missing nodes along the way.
    node_paths.sort_custom(func(a: NodePath, b: NodePath) -> bool:
        return a.get_name_count() < b.get_name_count())

    for node_path in node_paths:
        var save_dict: Dictionary = dict[node_path]
        save_dict = save_dict.duplicate()

        var scene_path: String = save_dict.get(_SCENE_FILE_PATH_KEY, "")
        save_dict.erase(_SCENE_FILE_PATH_KEY)
        if scene_path:
            scene_path = scene_path.simplify_path()
            if not scene_path.is_absolute_path() or not scene_path.is_valid_filename() \
                or not scene_path.begins_with("res://") or not scene_path.ends_with(".tscn"):
                push_warning("Invalid scene path ", scene_path, " for node ", node_path, ", ignoring")
                scene_path = ""

        var node := scene_tree.root.get_node_or_null(node_path)
        if node == null:
            var parent_path := NodeUtils.get_parent_path(node_path)
            var parent_node := scene_tree.root.get_node_or_null(parent_path)
            if not parent_node:
                push_error("Could not find parent for node ", node_path, " in order to load it")
                continue
            
            if not scene_path:
                push_error("Node ", node_path, " doesn't have a scene file, so cannot be loaded by instantiation")
                continue

            var scene: PackedScene = load(scene_path)
            node = scene.instantiate()
            node.add_to_group(SAVEABLE_GROUP)
            parent_node.add_child(node)
        
        if not node.is_in_group(SAVEABLE_GROUP):
            push_warning("Loaded node ", node_path, " is not marked as saveable, refusing to load it")
            continue
        
        node.call("load_from_dict", save_dict)
