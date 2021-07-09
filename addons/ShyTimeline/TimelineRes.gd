extends Resource
tool

class_name TimelineRes, "res://addons/ShyTimeline/Icons/Timeline.png"


export var events := {}
export var start_event := ""
export var name := ""


func get_unique_name(base) -> String:
	base = base.validate_node_name()
	if base in events.keys():
		var c = 0
		for i in events:
			if i.begins_with(base):
				c = max(c, int(i))
		return "%s%04d"%[base, c + 1]
	return base
