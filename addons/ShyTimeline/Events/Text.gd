@tool
extends "res://addons/ShyTimeline/EventRes.gd"


@export var text := "":
	set(new):
		text = new
		emit_changed()

static func get_event_type() -> String:
	return "Text"





func _load(data: Dictionary) -> void:
	text = data.get("text", text)


func _save() -> Dictionary:
	return {
		"text" : text
	}
