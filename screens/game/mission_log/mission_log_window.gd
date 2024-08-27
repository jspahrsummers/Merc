extends Window
class_name MissionLogWindow

@export var mission_list: ItemList
@export var description_label: RichTextLabel
@export var cost_label: Label
@export var reward_label: Label
@export var forfeit_button: Button
@export var premultiplied_canvas_material: CanvasItemMaterial

var mission_controller: MissionController

var _current_missions: Array[Mission]
var _selected_mission: Mission

func _ready() -> void:
    self._current_missions = self.mission_controller.get_current_missions()
    for mission: Mission in self._current_missions:
        self.mission_list.add_item(mission.title)
    
    self._clear()
    self.mission_controller.mission_started.connect(_add_mission)

    # TODO: Keep a log of past missions?
    self.mission_controller.mission_succeeded.connect(_remove_mission)
    self.mission_controller.mission_forfeited.connect(_remove_mission)
    self.mission_controller.mission_failed.connect(_remove_mission)

func _add_mission(mission: Mission) -> void:
    self._current_missions.push_back(mission)
    self.mission_list.add_item(mission.title)

func _remove_mission(mission: Mission) -> void:
    var index := self._current_missions.find(mission)
    self._current_missions.remove_at(index)
    assert(index != -1, "Can't find mission to remove")

    self.mission_list.deselect(index)
    self.mission_list.remove_item(index)
    if self._selected_mission == mission:
        self._clear()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_mission_log"):
        self.get_viewport().set_input_as_handled()
        self.queue_free()

func _on_close_requested() -> void:
    self.queue_free()

func _on_empty_clicked(_at_position: Vector2, _mouse_button_index: int) -> void:
    self._clear()

func _clear() -> void:
    self.description_label.text = ""
    self.cost_label.text = ""
    self.reward_label.text = ""
    self.forfeit_button.disabled = true
    self.forfeit_button.tooltip_text = "No mission selected."
    self._selected_mission = null

func _on_item_selected(index: int) -> void:
    self._selected_mission = self._current_missions[index]
    self.description_label.text = self._selected_mission.description
    self.cost_label.text = self._money_dict_to_string(self._selected_mission.starting_cost)
    self.reward_label.text = self._money_dict_to_string(self._selected_mission.monetary_reward)
    self.forfeit_button.disabled = false
    self.forfeit_button.tooltip_text = "Forfeit the mission, losing the initial deposit." if self._selected_mission.starting_cost else "Forfeit the mission."

func _money_dict_to_string(dict: Dictionary) -> String:
    var keys := dict.keys()
    keys.sort_custom(func(a: TradeAsset, b: TradeAsset) -> bool: return a.name < b.name)

    var lines: Array[String] = []
    for money: TradeAsset in keys:
        var amount: float = dict[money]
        lines.append(money.amount_as_string(amount))
    
    return "\n".join(lines)

func _on_forfeit_pressed() -> void:
    self.mission_controller.forfeit_mission(self._selected_mission)
