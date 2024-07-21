extends PanelContainer

@export var bank_account: BankAccount
@export var label_container: Container

var _labels_by_currency: Dictionary = {}

func _ready() -> void:
    self.bank_account.changed.connect(_update)
    self._update()

func _update() -> void:
    var existing_currencies := self._labels_by_currency.keys()
    for currency: Currency in existing_currencies:
        if currency not in self.bank_account.currencies:
            var label: Label = self._labels_by_currency[currency]
            label.queue_free()
            self._labels_by_currency.erase(currency)

    for currency: Currency in self.bank_account.currencies:
        var amount: int = self.bank_account.currencies[currency]

        var label: Label = self._labels_by_currency.get(currency)
        if label == null:
            label = Label.new()
            self.label_container.add_child(label)
            self._labels_by_currency[currency] = label
        
        label.text = "%s %s" % [float(amount) / currency.granularity, currency.name.to_lower()]
