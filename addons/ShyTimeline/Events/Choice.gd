extends "res://addons/ShyTimeline/EventRes.gd"
tool


export var choice_text := {}
export var choose_time := 0.0


func get_node_type() -> String:
	return "ChoiceEvent"


func create_control(id: int) -> Control:
	var new = LineEdit.new()
	new.text = choice_text.get(id, "")
	new.connect("text_changed", self, "_on_text_changed", [id])
	return new


func _on_text_changed(new: String, slot: int) -> void:
	choice_text[slot] = new
	emit_changed()


func slot_removed(idx) -> void:
	choice_text.erase(idx)
