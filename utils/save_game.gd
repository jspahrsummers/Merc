class_name SaveGame

## The group name used for nodes that can be saved and loaded.
const SAVEABLE_GROUP = "saveable"

## The directory to save and load games to/from.
const SAVE_GAMES_DIRECTORY = "user://save_games/"

## A private key used to store a node's [member Node.scene_file_path] when saving.
const _SCENE_FILE_PATH_KEY = "__scene_file_path"

## Returns the names of all existing save games.
static func get_save_game_names() -> Array[String]:
    var dir := DirAccess.open(SaveGame.SAVE_GAMES_DIRECTORY)
    if not dir:
        return []

    var paths: Array[String] = []

    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name:
        if not dir.current_is_dir() and file_name.ends_with(".json"):
            paths.append(file_name.substr(0, file_name.length() - 5))

        file_name = dir.get_next()
    
    return paths

## Saves all [i]saveable[/i] nodes in the scene tree to a file with the given name.
static func save(scene_tree: SceneTree, name: String) -> Error:
    if not DirAccess.dir_exists_absolute(SAVE_GAMES_DIRECTORY):
        var error := DirAccess.make_dir_recursive_absolute(SAVE_GAMES_DIRECTORY)
        if error != OK:
            return error

    var path := SAVE_GAMES_DIRECTORY.path_join(name + ".json")

    var save_dict := save_tree_to_dict(scene_tree)
    var json := JSON.stringify(save_dict, "\t", false)
    var file := FileAccess.open(path, FileAccess.WRITE)
    if not file:
        return FileAccess.get_open_error()

    file.store_string(json)
    file.close()
    print("Saved game to: ", path)
    return OK

## Serializes all [i]saveable[/i] nodes in the scene tree to a JSON-compatible dictionary.
static func save_tree_to_dict(scene_tree: SceneTree) -> Dictionary:
    # Hook to allow nodes to prepare for saving.
    scene_tree.call_group(SAVEABLE_GROUP, "before_save")

    var saveable_nodes := scene_tree.get_nodes_in_group(SAVEABLE_GROUP)
    var save_dict := {}
    for node in saveable_nodes:
        var node_path := node.get_path()
        var node_dict := {_SCENE_FILE_PATH_KEY: node.scene_file_path}
        node_dict.merge(node.call("save_to_dict") as Dictionary)
        save_dict[node_path] = node_dict

    scene_tree.call_group_flags(SceneTree.GROUP_CALL_REVERSE, SAVEABLE_GROUP, "after_save")
    return save_dict

## Loads saveable nodes from a file into the scene tree, merging with existing nodes.
static func load(scene_tree: SceneTree, name: String) -> Error:
    var path := SAVE_GAMES_DIRECTORY.path_join(name + ".json")
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
    print("Loaded game from: ", path)
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

static func load_resource_property_from_dict(object: Object, dict: Dictionary, property_name: StringName) -> void:
    var resource: SaveableResource = object.get(property_name)
    if not resource:
        return

    var value: Dictionary = dict[property_name]
    resource.load_from_dict(value)

static func save_resource_property_into_dict(object: Object, dict: Dictionary, property_name: StringName) -> void:
    var resource: SaveableResource = object.get(property_name)
    if not resource:
        return

    dict[property_name] = resource.save_to_dict()

static func serialize_vector3(vector: Vector3) -> Array[float]:
    return [vector.x, vector.y, vector.z]

static func deserialize_vector3(value: Variant) -> Vector3:
    var array: Array[float] = value
    return Vector3(array[0], array[1], array[2])

static func serialize_basis(basis: Basis) -> Array[Array]:
    return [
        serialize_vector3(basis.x),
        serialize_vector3(basis.y),
        serialize_vector3(basis.z),
    ]

static func deserialize_basis(value: Variant) -> Basis:
    var array: Array[Array] = value
    return Basis(
        deserialize_vector3(array[0]),
        deserialize_vector3(array[1]),
        deserialize_vector3(array[2]),
    )

static func serialize_transform(transform: Transform3D) -> Dictionary:
    return {
        "origin": serialize_vector3(transform.origin),
        "basis": serialize_basis(transform.basis),
    }

static func deserialize_transform(value: Variant) -> Transform3D:
    var dict: Dictionary = value
    var basis: Array[Array] = dict["basis"]
    var origin: Array[float] = dict["origin"]

    return Transform3D(
        deserialize_basis(basis),
        deserialize_vector3(origin),
   )
