extends Resource
tool


export var next_events := {0 : []}
export var pos := Vector2.ZERO
export var channel := ""


static func get_node_type() -> String:
	return "BaseNode"


func create_control(id: int) -> Control:
	var new = Label.new()
	new.text = str(id)
	return new


func save() -> Dictionary:
	var data = {}
	data.position = pos
	data.events = next_events
	data.channel = channel
	data.data = _save()
	return data


func load(data: Dictionary) -> void:
	pos = data.get("position", pos)
	next_events = data.get("events", next_events)
	channel = data.get("channel", channel)
	_load(data.get("data", {}))


func slot_removed(idx: int) -> void:
	pass


func _load(data: Dictionary) -> void:
	pass


func _save() -> Dictionary:
	return {}
