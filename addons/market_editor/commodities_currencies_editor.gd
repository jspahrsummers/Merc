extends EditorProperty

const COMMODITIES_DIRECTORY = "res://mechanics/economy/commodities/"
const CURRENCIES_DIRECTORY = "res://mechanics/economy/currencies/"

var _value: Dictionary
var _updating := false
var _spinners := {}

func _init() -> void:
    var container := GridContainer.new()
    container.columns = 2
    self.add_child(container)

    for trade_asset in self._get_all_trade_assets():
        var label := Label.new()
        label.text = trade_asset.name
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        container.add_child(label)

        var spinner := SpinBox.new()
        spinner.max_value = 10000.0
        spinner.allow_greater = true
        spinner.custom_arrow_step = 1.0
        spinner.value_changed.connect(func(new_value: float) -> void:
            self._on_value_changed(trade_asset, new_value))
        container.add_child(spinner)
        self.add_focusable(spinner)
        self._spinners[trade_asset] = spinner

func _get_money() -> TradeAsset:
    return self.get_edited_object().money

func _on_value_changed(trade_asset: TradeAsset, new_value: float) -> void:
    if self._updating:
        return

    if is_zero_approx(new_value):
        self._value.erase(trade_asset)
    else:
        self._value[trade_asset] = new_value
    
    self.emit_changed(self.get_edited_property(), self._value)

func _update_property() -> void:
    self._updating = true

    self._value = self.get_edited_object()[self.get_edited_property()].duplicate()

    for trade_asset in self._spinners:
        var spinner: SpinBox = self._spinners[trade_asset]
        if trade_asset == self._get_money():
            spinner.value = 1.0
            spinner.editable = false
        else:
            spinner.step = 1.0 if trade_asset is Commodity else 0.0
            spinner.value = self._value.get(trade_asset, 0.0)
            spinner.editable = true
    
    self._updating = false

func _set_read_only(read_only: bool) -> void:
    for trade_asset in self._spinners:
        self._spinners[trade_asset].editable = not read_only

func _get_all_trade_assets() -> Array[TradeAsset]:
    var trade_assets: Array[TradeAsset] = []

    for file in DirAccess.get_files_at(CURRENCIES_DIRECTORY):
        trade_assets.push_back(load("%s/%s" % [CURRENCIES_DIRECTORY, file]))

    for file in DirAccess.get_files_at(COMMODITIES_DIRECTORY):
        trade_assets.push_back(load("%s/%s" % [COMMODITIES_DIRECTORY, file]))

    return trade_assets
