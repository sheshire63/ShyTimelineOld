extends "res://addons/ShyTimeline/EventRes.gd"
tool


const TYPES = {
		TYPE_STRING: "String",
		TYPE_BOOL: "Boolean",
		TYPE_INT: "Integer",
		TYPE_REAL: "Float",}

const CONTROLS = {
		TYPE_STRING: LineEdit,
		TYPE_BOOL: CheckButton,
		TYPE_INT: SpinBox,
		TYPE_REAL: SpinBox,
}

const CONTROL_PROPERTY = {
		TYPE_STRING: "text",
		TYPE_BOOL: "pressed",
		TYPE_INT: "value",
		TYPE_REAL: "value",
}

const CONTROL_METHOD = {
		TYPE_STRING: "text_changed",
		TYPE_BOOL: "toggled",
		TYPE_INT: "value_changed",
		TYPE_REAL: "value_changed",
}

const DEFAULT_VALUES = {
		TYPE_STRING: "",
		TYPE_BOOL: true,
		TYPE_INT: 0,
		TYPE_REAL: 0.0,
}


# to array of dicts
export var inputs := {}
export var input_time := 0.0


static func get_event_type() -> String:
	return "Input"


func create_control(id: int) -> Control:
	var box = HBoxContainer.new()
	var type_c = OptionButton.new()
	var label := LineEdit.new()
	label.connect("text_changed", self, "_on_var_changed", [id])
	for i in TYPES:
		type_c.add_item(TYPES[i], i)
	type_c.connect("item_selected", self, "_on_type_selected", [box, id])
	box.add_child(label)
	box.add_child(type_c)
	box.add_child(Control.new())
	
	if not id in inputs:
		inputs[id] = {"type": TYPE_STRING, "value": "", "variable": ""}
	type_c.select(type_c.get_item_index(inputs[id].type))
	label.text = inputs[id].variable
	_on_type_selected(TYPES.keys().find(inputs[id].type), box, id)
	return box


func _on_var_changed(new: String, id: int) -> void:
	inputs[id].variable = new


func _on_type_selected(type: int, box: Container, id:int) -> void:
	type = TYPES.keys()[type]
	var control: Control = CONTROLS[type].new()
	control.connect(CONTROL_METHOD[type], self, "_on_value_set", [id])
	control.set(CONTROL_PROPERTY[type], inputs[id].get("value", DEFAULT_VALUES[type]))
	box.get_children()[-1].queue_free()
	box.add_child(control)
	inputs[id].type = type


func slot_removed(idx: int) -> void:
	inputs.erase(idx)


#used for exporting and copying the node:
func _load(data: Dictionary) -> void:
	inputs = data.get("inputs", inputs)


func _save() -> Dictionary:
	return {
		"input" : inputs
	}


func _on_value_set(new, id:int) -> void:
	inputs[id].value = new
