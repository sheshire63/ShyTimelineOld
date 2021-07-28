extends "res://addons/ShyTimeline/EventRes.gd"
tool


export var text := "" setget _set_text


static func get_node_type() -> String:
	return "TextEvent"


func _set_text(new) -> void:
	text = new
	emit_changed()


func _load(data: Dictionary) -> void:
	text = data.get("text", text)


func _save() -> Dictionary:
	return {
		"text" : text
	}
