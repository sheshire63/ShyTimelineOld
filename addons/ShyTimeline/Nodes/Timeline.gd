extends Node
tool

class_name Timeline, "res://addons/ShyTimeline/Icons/Timeline.png"


const Rollback_stop_events := ["TextEvent"] # events that the rollback option not skipps when going back

signal finished
signal handle_event
signal handle_event_rollback #for rollback
signal handle_event_rollforward
signal stop_all

export var timeline_res: Resource = TimelineRes.new() setget _set_timeline
export var autostart := false
export var settings := {}

var history := []
var future := []
var active_events := []
var event_queue := []
var is_active := false
var c := 1


#func _get_property_list() -> Array:
#	return[{
#		name = "timeline_res",
#		type = TYPE_OBJECT,
#		hint = PROPERTY_HINT_RESOURCE_TYPE,
#		hint_string = "TimelineRes"
#	}]


func _ready() -> void:
	if Engine.editor_hint:
		return
	connect("handle_event", self, "_default_handler")
	Saves.connect("request_save", self, "save_state")
	Saves.connect("request_load_save", self, "load_state")
	if autostart:
		is_active = true
		event_queue.append(timeline_res.start_event)


func _process(_delta: float) -> void:
	if Engine.editor_hint or !is_active:
		return
	if event_queue:
		handle(event_queue.pop_front())
	if event_queue.empty() and active_events.empty():
		emit_signal("finished")
		is_active = false
		print("Timeline Finished: %s"%timeline_res.name)


"""
handles events
"""
func handle(event: String) -> void:
	if event in timeline_res.events.keys():
		is_active = true
		emit_signal("handle_event", timeline_res.events[event], event, c)
		active_events.append(event)
		history.append({"event": event, "id": c})
		c += 1
	else:
		printerr("ShyTimeline: event: %s not in Timeline: %s"%[event, timeline_res.name])


"""
call from event_handlers after they finished handling a event
"""
func event_handled(event: String, _continue := true) -> void:
	if not event in active_events:
		return
	active_events.erase(event)
	if _continue:
		var next_events = timeline_res.events[event].next_events[0].duplicate()
		event_queue.append_array(next_events)


func _unhandled_key_input(input_event: InputEventKey) -> void:
	if input_event.is_action_pressed("ui_up"):
		if history:
			if !future:
				future.append(history.pop_back())#skip the current event
			var do = true
			while do and history:
				var item = history.pop_back()
				var event = timeline_res.events[item.event]
				emit_signal("handle_event_rollback", event, item)
				future.append(item)
				do = not event.get_node_type() in Rollback_stop_events and history
			
	if input_event.is_action_pressed("ui_down"):
		if future:
			if !history:
				history.append(future.pop_back())
			var do = true
			while do and future:
				var item = future.pop_back()
				var event = timeline_res.events[item.event]
				emit_signal("handle_event_rollforward", event, item)
				history.append(item)
				
				do = not event.get_node_type() in Rollback_stop_events and future


"""
adds a event manualy to the queue
intended if the handler pauses and should continue on the next event call
"""
func queue(id: String) -> void:
	event_queue.append(id)
	is_active = true


"""
removes a event manualy from the queue
intended to remove an event added by queue()
"""
func remove_from_queue(id: String) -> void:
	event_queue.erase(id)


"""
handles all next events from a given events slot
to trigger a second choice of an event
"""
func handle_branch(event: String, choice:= 0) -> void:
	if event in timeline_res.events.keys():
		is_active = true
		for i in timeline_res.events[event].next_events[choice]:
			handle(i)
	else:
		printerr("ShyTimeline: event: %s not in Timeline: %s"%[event, timeline_res.name])


func get_setting(setting: String):
	var path = "ShyTimeline/settings/" + setting
	return settings.get(setting, ProjectSettings.get_setting(path)
			if ProjectSettings.has_setting(path) else
			Settings.settings.get(setting, null))


func save_state() -> void:
	var state = {}
	state["history"] = history
	state["future"] = future
	state["active_events"] = active_events
	state["event_queue"] = event_queue
	state["counter"] = c
	Settings.states[_to_string()] = state


func load_state() -> void:
	var state = Settings.states[_to_string()]
	history = state.get("history", [])
	future = state.get("future", [])
	active_events = state.get("active_events", [])
	event_queue = state.get("event_queue", [])
	c = state.get("counter")


func _set_timeline(new) -> void:
	timeline_res = new
	active_events = []
	event_queue = []


func _default_handler(event: Resource, event_id: String, id: int) -> void:
	if event.get_event_type() == "condition":
		var flag := true
		for i in event.conditions.size():
			var value := ""
			var condition: Array = Variables.format_text("{\"True\"" + event.conditions[i] + "}")
			for j in condition:
				value += j.text
			if value != "":
				handle_branch(event_id, i)
			else:
				flag = false
		event_handled(event_id, flag)
