extends Resource
class_name SaveableResource

## The base class for any resource that should have its current state saved into any save game files, instead of being recreated in its initial state when a game is loaded.
##
## Resources that do not inherit from SaveableResource will not be saved to disk.

## Saves this resource to a JSON-compatible dictionary.
##
## The default implementation should be suitable to serialize primitives and other [SaveableResource]s, but can be overridden to serialize properties of other types. Only properties tagged as [constant PROPERTY_USAGE_STORAGE] will be saved.
func save_to_dict() -> Dictionary:
    var ignore_properties := ClassDB.class_get_property_list(&"Resource").map(func(property: Dictionary) -> String: return property["name"])
    ignore_properties.push_back("script")

    var save_dict := {}
    for property: Dictionary in self.get_property_list():
        var property_name: String = property.name
        if property_name in ignore_properties:
            continue

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
                elif ClassDB.is_parent_class(classname, &"Resource"):
                    var nested_resource: Resource = self.get(property_name)
                    if not nested_resource.resource_path:
                        push_warning("save_to_dict: Cannot save resource property ", property_name, " as it does not have an on-disk path")
                        continue
                    
                    save_dict[property_name] = nested_resource.resource_path
                else:
                    push_warning("save_to_dict: Cannot save property ", property_name, " of class ", classname)

            _:
                save_dict[property_name] = self.get(property_name)

    return save_dict

## Loads this resource's values from a JSON dictionary.
##
## The default implementation should be suitable to load primitives and other [SaveableResource]s, but can be overridden to load properties of other types. Only properties tagged as [constant PROPERTY_USAGE_STORAGE] will be loaded.
func load_from_dict(dict: Dictionary) -> void:
    var properties_by_name := {}
    for property: Dictionary in self.get_property_list():
        properties_by_name[property.name] = property

    for property_name: String in dict:
        if not properties_by_name.has(property_name):
            push_error("load_from_dict: Saved property ", property_name, " not found on object")
            continue

        var property: Dictionary = properties_by_name[property_name]
        var usage_flags: PropertyUsageFlags = property.usage
        if usage_flags & PROPERTY_USAGE_STORAGE == 0:
            push_warning("load_from_dict: Ignoring property ", property_name, " not marked for storage")
            continue
        
        var value: Variant = dict[property_name]
        var type: Variant.Type = property.type
        match type:
            TYPE_OBJECT:
                var classname: StringName = property["class_name"]
                if ClassDB.is_parent_class(classname, &"SaveableResource"):
                    var value_dict := value as Dictionary
                    if not value_dict:
                        push_warning("load_from_dict: Object property ", property_name, " was not serialized as a dictionary")
                        continue

                    var nested_resource: SaveableResource = ClassDB.instantiate(classname)
                    nested_resource.load_from_dict(value_dict)
                    self.set(property_name, nested_resource)
                elif ClassDB.is_parent_class(classname, &"Resource"):
                    var value_str := value as String
                    if not value_str:
                        push_warning("load_from_dict: Resource property ", property_name, " was not serialized as a string path")
                        continue

                    var nested_resource := ResourceUtils.safe_load_resource(value_str, "tres")
                    self.set(property_name, nested_resource)
                else:
                    push_warning("load_from_dict: Cannot load property ", property_name, " of class ", classname)

            _:
                self.set(property_name, value)

    self.emit_changed()
