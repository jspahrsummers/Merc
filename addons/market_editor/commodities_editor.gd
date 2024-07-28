extends EditorProperty

const COMMODITIES_DIRECTORY = "res://mechanics/economy/commodities/"

var _value: Dictionary
var _updating := false
var _checkboxes := {}
var _sliders := {}

func _init() -> void:
    var container := GridContainer.new()
    container.columns = 2
    self.add_child(container)

    for commodity in self._get_all_commodities():
        var checkbox := CheckBox.new()
        checkbox.text = commodity.name
        checkbox.toggled.connect(func(toggled_on: bool) -> void:
            self._on_toggled(commodity, toggled_on))
        container.add_child(checkbox)
        self._checkboxes[commodity] = checkbox

        var slider := HSlider.new()
        slider.size_flags_horizontal = SIZE_EXPAND_FILL
        slider.max_value = 1.0
        slider.value = 0.5
        slider.step = 0.01
        slider.tick_count = 5
        slider.value_changed.connect(func(new_value: float) -> void:
            self._on_value_changed(commodity, new_value))
        container.add_child(slider)
        self.add_focusable(slider)
        self._sliders[commodity] = slider

func _get_money() -> TradeAsset:
    return self.get_edited_object().money

func _on_toggled(commodity: Commodity, toggled_on: bool) -> void:
    if self._updating:
        return
    
    if toggled_on:
        self._sliders[commodity].editable = true
        self._value[commodity] = self._sliders[commodity].value
    else:
        self._sliders[commodity].editable = false
        self._value.erase(commodity)

    self.emit_changed(self.get_edited_property(), self._value)

func _on_value_changed(commodity: Commodity, new_value: float) -> void:
    if self._updating:
        return

    assert(commodity in self._value, "Expected commodity to already be enabled")
    self._value[commodity] = new_value
    
    self.emit_changed(self.get_edited_property(), self._value)

func _update_property() -> void:
    self._updating = true

    self._value = self.get_edited_object()[self.get_edited_property()].duplicate()

    for commodity in self._checkboxes:
        var checkbox: CheckBox = self._checkboxes[commodity]
        checkbox.button_pressed = commodity in self._value

    for commodity in self._sliders:
        var slider: HSlider = self._sliders[commodity]
        slider.value = self._value.get(commodity, 0.5)
        slider.editable = commodity in self._value
    
    self._updating = false

func _set_read_only(read_only: bool) -> void:
    for commodity in self._sliders:
        self._checkboxes[commodity].disabled = read_only
        self._sliders[commodity].editable = not read_only

func _get_all_commodities() -> Array[Commodity]:
    var result: Array[Commodity] = []

    for file in DirAccess.get_files_at(COMMODITIES_DIRECTORY):
        result.push_back(load("%s/%s" % [COMMODITIES_DIRECTORY, file]))

    return result
