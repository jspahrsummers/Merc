extends EditorProperty

var value: Dictionary

var _updating := false
var _spinners := {}

func _init(property_name: String, main_currency: Resource) -> void:
    var container := GridContainer.new()
    container.columns = 2
    self.add_child(container)

    for resource in self._get_all_resources(property_name):
        if resource == main_currency:
            continue

        var label := Label.new()
        label.text = resource.name
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        container.add_child(label)

        var spinner := SpinBox.new()
        spinner.max_value = 10000 * Currency.GRANULARITY
        spinner.allow_greater = true
        spinner.rounded = true
        spinner.custom_arrow_step = Currency.GRANULARITY
        spinner.value_changed.connect(func(new_value: float) -> void:
            self._on_value_changed(resource, new_value))
        container.add_child(spinner)
        self.add_focusable(spinner)
        self._spinners[resource] = spinner

func _on_value_changed(resource: Resource, new_value: float) -> void:
    if self._updating:
        return

    var price := roundi(new_value)
    if price > 0:
        self.value[resource] = price
    else:
        self.value.erase(resource)
    
    self.emit_changed(self.get_edited_property(), self.value)

func _update_property() -> void:
    self._updating = true

    self.value = self.get_edited_object()[self.get_edited_property()].duplicate()
    for resource in self._spinners:
        self._spinners[resource].value = self.value.get(resource, 0.0)
    
    self._updating = false

func _get_all_resources(property_name: String) -> Array[Resource]:
    var resources: Array[Resource] = []
    var dir := "res://mechanics/economy/%s/" % property_name
    for file in DirAccess.get_files_at(dir):
        resources.push_back(load("%s/%s" % [dir, file]))

    return resources
