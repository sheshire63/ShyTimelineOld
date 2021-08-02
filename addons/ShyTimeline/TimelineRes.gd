extends Resource
tool

class_name TimelineRes, "res://addons/ShyTimeline/Icons/Timeline.png"


export var events := {} setget _set_events
export var start_event := ""
export var name := ""


func _set_events(new) -> void:
	events = new
	for i in events:
		if not events[i].is_connected("changed", self, "_on_event_changed"):
			events[i].connect("changed", self, "_on_event_changed", [events[i]])


func get_unique_name(base: String) -> String:
	base = base.validate_node_name().rstrip(str(int(base)))
	if base in events.keys():
		var c = 0
		for i in events:
			if i.begins_with(base):
				c = max(c, int(i))
		return "%s%d"%[base, c + 1]
	return base


func add_event(new: Resource, name:= "") -> String:
	if name == "":
		name = new.get_event_type()
	name = get_unique_name(name)
	if not new.is_connected("changed", self, "_on_event_changed"):
		new.connect("changed", self, "_on_event_changed", [new])
	events[name] = new
	return name


func _on_event_changed(event: Resource) -> void:
	ResourceSaver.save(event.resource_path, event)
	ResourceSaver.save(resource_path, self)
