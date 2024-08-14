extends Window
class_name MissionComputerWindow

@export var mission_list: ItemList
@export var description_label: RichTextLabel
@export var cost_label: Label
@export var reward_label: Label
@export var start_button: Button
@export var premultiplied_canvas_material: CanvasItemMaterial

var available_missions: Array[Mission]
var mission_controller: MissionController
var cargo_hold: CargoHold
var bank_account: BankAccount

var _selected_mission: Mission

func _ready() -> void:
    self._clear()

    for mission in self.available_missions:
        self.mission_list.add_item(mission.title)

func _on_close_requested() -> void:
    self.visible = false

func _on_empty_clicked(_at_position: Vector2, _mouse_button_index: int) -> void:
    self._clear()

func _clear() -> void:
    self.description_label.text = ""
    self.cost_label.text = ""
    self.reward_label.text = ""
    self.start_button.disabled = true
    self.start_button.tooltip_text = "No mission selected."
    self._selected_mission = null

func _on_item_selected(index: int) -> void:
    self._selected_mission = self.available_missions[index]
    self.description_label.text = self._selected_mission.description
    self.cost_label.text = self._money_dict_to_string(self._selected_mission.starting_cost)
    self.reward_label.text = self._money_dict_to_string(self._selected_mission.monetary_reward)

    if not self._can_pay_starting_cost():
        self.start_button.disabled = true
        self.start_button.tooltip_text = "Cannot afford deposit."
        return

    if not self._can_fit_cargo():
        self.start_button.disabled = true
        self.start_button.tooltip_text = "Not enough room for this cargo."
        return
    
    self.start_button.disabled = false
    self.start_button.tooltip_text = "Pay the deposit and start the mission."

func _money_dict_to_string(dict: Dictionary) -> String:
    var keys := dict.keys()
    keys.sort_custom(func(a: TradeAsset, b: TradeAsset) -> bool: return a.name < b.name)

    var lines: Array[String] = []
    for money: TradeAsset in keys:
        var amount: float = dict[money]
        lines.append(money.amount_as_string(amount))
    
    return "\n".join(lines)

func _can_pay_starting_cost() -> bool:
    for trade_asset: TradeAsset in self._selected_mission.starting_cost:
        var required_amount: float = self._selected_mission.starting_cost[trade_asset]
        if trade_asset.current_amount(self.cargo_hold, self.bank_account) < required_amount:
            return false
    
    return true

func _can_fit_cargo() -> bool:
    var required_volume: float = 0.0
    for commodity: Commodity in self._selected_mission.cargo:
        required_volume += self._selected_mission.cargo[commodity] * commodity.volume

    return self.cargo_hold.get_occupied_volume() + required_volume <= self.cargo_hold.max_volume

func _on_start_pressed() -> void:
    if not self.mission_controller.start_mission(self._selected_mission):
        push_error("Failed to start mission")
        return
    
    var index := self.available_missions.find(self._selected_mission)
    assert(index != -1, "Cannot find selected mission in available missions")

    self.available_missions.remove_at(index)
    self.mission_list.deselect_all()
    self.mission_list.remove_item(index)
    self._clear()
