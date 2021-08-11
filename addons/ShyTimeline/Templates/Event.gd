@tool
extends "res://addons/ShyTimeline/EventRes.gd"
#create a copy and place it in "res://addons/ShyTimeline/Events/"


#if you want to use a custom node change this:
#static func get_node() -> GraphNode:
#	return load("res://addons/ShyTimeline/Editor/NodeBase.tscn").instance()


static func get_event_type() -> String:
	return "YourEventType"


# change for a different slot Control:
#func create_control(id: int) -> Control:
#	return Control.new()


func slot_removed(idx: int) -> void:
	pass


#used for exporting and copying the node:
func _load(data: Dictionary) -> void:
	pass


func _save() -> Dictionary:
	return {}
