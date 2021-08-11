@tool
extends Node


class_name BaseHandler


@export var settings := {}

@onready var timeline = get_parent()

var settings_override := {}


func _get_configuration_warning() -> String:
	if not get_parent() is Timeline:
		return "needs to be a child of Timeline"
	return ""


func _ready() -> void:
	if Engine.editor_hint:
		return
	Saves.connect("request_save", save_state)
	Saves.connect("request_load_save", load_state)
	if !timeline:
		print("timeline not found")
	timeline.connect("handle_event", _on_handle_event)
	timeline.connect("handle_event_rollback", _on_rollback)
	timeline.connect("handle_event_rollforward", _on_rollforward)


func save_state() -> void:
	var state = _save()
	Settings.states[_to_string()] = state


func load_state() -> void:
	var state = Settings.states[_to_string()]
	_load(state)


func get_setting(setting: String):
	return settings_override.get(setting, timeline.get_setting(setting))


# to overwrite:
func _on_handle_event(event: Resource, event_id: String, id: int) -> void:
	if event.get_node_type() == "BaseEvent":
		timeline.event_handled(event_id)


func _process(_delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	pass


func _on_rollback(_res: Resource, id: String) -> void:
	pass


func _on_rollforward(_res: Resource, event: Dictionary, fast:= false) -> void:
	pass


func _save() -> Dictionary:
	return {}


func _load(save: Dictionary):
	pass
