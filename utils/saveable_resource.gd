extends Resource
class_name SaveableResource

## The base class for any resource that should have its current state saved into any save game files, instead of being recreated in its initial state when a game is loaded.
##
## Resources that do not inherit from SaveableResource will not be saved to disk.

## Saves this resource to a JSON-compatible dictionary.
##
## The default implementation should be suitable to serialize primitives and other [SaveableResource]s, but can be overridden to serialize properties of other types. Only properties tagged as [constant PROPERTY_USAGE_STORAGE] will be saved.
func save_to_dict() -> Dictionary:
    var save_dict := {}
    for property: Dictionary in self.get_property_list():
        var property_name: String = property.name
        var usage_flags: PropertyUsageFlags = property.usage
        if usage_flags & PROPERTY_USAGE_STORAGE == 0:
            continue
        
        var type: Variant.Type = property.type
        match type:
            TYPE_RID, TYPE_CALLABLE, TYPE_SIGNAL:
                push_warning("save_to_dict: Cannot save property ", property_name, " of type ", type)
            
            TYPE_OBJECT:
                var classname: StringName = property["class_name"]
                if ClassDB.is_parent_class(classname, &"SaveableResource"):
                    var nested_resource: SaveableResource = self.get(property_name)
                    save_dict[property_name] = nested_resource.save_to_dict()
                else:
                    push_warning("save_to_dict: Cannot save property ", property_name, " of class ", classname)

            _:
                save_dict[property_name] = self.get(property_name)

    return save_dict

## Loads this resource's values from a JSON dictionary.
##
## The default implementation should be suitable to load primitives and other [SaveableResource]s, but can be overridden to load properties of other types. Only properties tagged as [constant PROPERTY_USAGE_STORAGE] will be loaded.
func load_from_dict(dict: Dictionary) -> void:
    for property: Dictionary in self.get_property_list():
        var property_name: String = property.name
        if not dict.has(property_name):
            push_warning("load_from_dict: Missing property ", property_name)
            continue

        var usage_flags: PropertyUsageFlags = property.usage
        if usage_flags & PROPERTY_USAGE_STORAGE == 0:
            push_warning("load_from_dict: Ignoring property ", property_name, " not marked for storage")
            continue
        
        var value: Variant = dict[property_name]
        var type: Variant.Type = property.type
        match type:
            TYPE_OBJECT:
                var value_dict := value as Dictionary
                if not value_dict:
                    push_warning("load_from_dict: Object property ", property_name, " was not serialized as a dictionary")
                    continue

                var classname: StringName = property["class_name"]
                if ClassDB.is_parent_class(classname, &"SaveableResource"):
                    var nested_resource: SaveableResource = ClassDB.instantiate(classname)
                    nested_resource.load_from_dict(value_dict)
                    self.set(property_name, nested_resource)
                else:
                    push_warning("load_from_dict: Cannot load property ", property_name, " of class ", classname)

            _:
                self.set(property_name, value)
