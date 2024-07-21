extends PanelContainer

@export var cargo_hold: CargoHold
@export var label_container: Container
@export var free_cargo_label: Label

var _labels_by_commodity: Dictionary = {}

func _ready() -> void:
    self.cargo_hold.changed.connect(_update)
    self._update()

func _update() -> void:
    self.label_container.remove_child(self.free_cargo_label)

    var existing_commodities := self._labels_by_commodity.keys()
    for commodity: Commodity in existing_commodities:
        if commodity not in self.cargo_hold.commodities:
            var label: Label = self._labels_by_commodity[commodity]
            label.queue_free()
            self._labels_by_commodity.erase(commodity)

    for commodity: Commodity in self.cargo_hold.commodities:
        var amount: int = self.cargo_hold.commodities[commodity]

        var label: Label = self._labels_by_commodity.get(commodity)
        if label == null:
            label = Label.new()
            self.label_container.add_child(label)
            self._labels_by_commodity[commodity] = label
        
        label.text = "%s %s" % [amount, commodity.name.to_lower()]
    
    self.free_cargo_label.text = "%s L free" % (self.cargo_hold.max_volume - self.cargo_hold.get_occupied_volume())
    self.label_container.add_child(self.free_cargo_label)
