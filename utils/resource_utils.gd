class_name ResourceUtils

## Attempts to load a resource from a path, restricting the loading to the game's bundle, to avoid dynamic code injection from the user's filesystem.
static func safe_load_resource(path: String, type: String) -> Resource:
    path = path.simplify_path()
    if not path.is_absolute_path() or not path.begins_with("res://") or not path.ends_with(".%s" % type):
        push_warning("Invalid resource path ", path, ", ignoring")
        return null
    
    return load(path)
