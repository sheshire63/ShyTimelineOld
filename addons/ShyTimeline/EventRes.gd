extends Resource
tool


export var next_events := {0 : []}
export var pos := Vector2.ZERO
export var channel := ""


static func get_node() -> GraphNode:
	return load("res://addons/ShyTimeline/Editor/NodeBase.tscn").instance()


static func get_event_type() -> String:
	return "Base"


func create_control(id: int) -> Control:
	var new = Label.new()
	new.text = str(id)
	return new


func save() -> Dictionary:
	var data = {}
	data.pos_x = pos.x
	data.pos_y = pos.y
	data.events = next_events.duplicate(true)
	data.channel = channel
	data.data = _save().duplicate(true)
	data.type = get_event_type()
	return data


func load(data: Dictionary) -> void:
	var position := Vector2.ZERO
	position.x = data.get("pos_x", pos.x)
	position.y = data.get("pos_y", pos.y)
	pos = position
	next_events = data.get("events", next_events)
	channel = data.get("channel", channel)
	_load(data.get("data", {}))


func slot_removed(idx: int) -> void:
	pass


func _load(data: Dictionary) -> void:
	pass


func _save() -> Dictionary:
	return {}
