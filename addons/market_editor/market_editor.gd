@tool
extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
    return object is Market

func _parse_property(object: Object, type: int, name: String, hint_type: int, hint_string: String, usage_flags: int, wide: bool) -> bool:
    if not (object is Market):
        return false
    
    if name != "trade_assets":
        return false
    
    var control := preload ("res://addons/market_editor/commodities_currencies_editor.gd").new()
    self.add_property_editor(name, control)
    return true
