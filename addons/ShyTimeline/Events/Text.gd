extends "res://addons/ShyTimeline/EventRes.gd"
tool


export var text := "" setget _set_text


static func get_node_type() -> String:
	return "TextEvent"


func _set_text(new) -> void:
	text = new
	emit_changed()
