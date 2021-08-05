extends "res://addons/ShyTimeline/EventRes.gd"
tool


export(Array, String) var conditions = []

static func get_event_type() -> String:
	return "YourEventType"


func create_control(id: int) -> Control:
	conditions.append("")
	var new = LineEdit.new()
	new.connect("text_changed", self, "_on_text_entered", [id])
	return new


func _on_text_entered(text:String, id: int) -> void:
	conditions[id] = text


func slot_removed(idx: int) -> void:
	conditions.remove(idx)


#used for exporting and copying the node:
func _load(data: Dictionary) -> void:
	conditions = data.text


func _save() -> Dictionary:
	return {"text": conditions}
