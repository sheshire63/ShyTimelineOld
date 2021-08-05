extends BaseHandler
tool

class_name TextHandler


signal _continue

export(NodePath) var text_label_path
export var interrupt := false
export var stop_on_interrupt := false

var text_label: Control
var tween := Tween.new()
var timer := Timer.new()
var is_active := false
var _queue := []
var _history := []
var _future := []
var _segments := []
var _segment := 0
var current_event : Dictionary


func _get_configuration_warning() -> String:
	if not get_parent() is Timeline:
		return "needs to be a child of Timeline"
	# only allow RichTextLabel because of bbcode?
	if text_label_path and "bbcode_text" in get_node(text_label_path).get_property_list():
		return "the text label has no text property"
	return ""


func _ready() -> void:
	if Engine.editor_hint:
		return
	if text_label_path:
		text_label = get_node(text_label_path)
	else:
		text_label = RichTextLabel.new()
		text_label.set_anchors_preset(Control.PRESET_WIDE)
		var canvas = CanvasLayer.new()
		text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(canvas)
		canvas.add_child(text_label)
	add_child(tween)
	timer.one_shot = true
	add_child(timer)


func _on_handle_event(event: Resource, event_id: String, id: int) -> void:
	if event.get_event_type() == "Text":
		if interrupt:
			_start_handle(event, event_id, id)
			tween.stop_all()
			tween.emit_signal("tween_all_completed")
			timer.stop()
		else:
			_queue.append({"event": event, "event_id": event_id, "id": id})


func _process(_delta: float) -> void:
	if current_event and !is_active:
		if _segments.size() <= _segment:
			_finish_handle()
		else:
			_handle_segment(_segments[_segment], current_event.event)
	elif _queue and (interrupt or !is_active):
		var tmp = _queue.pop_front()
		_start_handle(tmp.event, tmp.event_id, tmp.id)


func _input(event: InputEvent) -> void:
	if is_active and event.is_action_pressed("ui_accept"):
		if tween.is_active():
			tween.stop_all()
			tween.emit_signal("tween_all_completed")
		elif !timer.is_stopped():
			timer.stop()
		else:
			emit_signal("_continue")
		get_tree().set_input_as_handled()


func _start_handle(event: Resource, event_id: String, id: int) -> void:
	settings_override = {}
	current_event = {"event": event_id, "id": id}
	_segment = 0
	_segments = Variables.format_text(event.text, get_setting("wait_after_line"))
	_history.append({"segments": _segments, "event": event, "id": id})
	if _history.size() > get_setting("rollback_history_length"):
		_history.pop_front()
	text_label.bbcode_text = ""
	text_label.visible_characters = 0
	text_label.visible = true


func _finish_handle() -> void:
	if !_future:
		timeline.event_handled(current_event.event)
	current_event = {}
	text_label.bbcode_text = ""
	text_label.visible = false


func _handle_segment(segment: Dictionary, id: String, instant := false) -> void:
	is_active = true
	var old_length: int = text_label.text.length()
	text_label.bbcode_text += segment.get("text", "")
	text_label.visible_characters = old_length
	if segment.get("action") == "end_line":
		text_label.bbcode_text += "\n"
	var new_length = text_label.text.length() - old_length
	tween.remove_all()
	if !instant:
		tween.interpolate_property(text_label, "visible_characters", old_length,
				text_label.text.length(), new_length / get_setting("chars_per_sek"))
		tween.start()
		yield(tween, "tween_all_completed")
	text_label.percent_visible = 1.0
	if !instant:
		match segment.get("action"):
			"wait", "w", "end_line":
				if segment.value != "":
					timer.start(segment.value)
					yield(timer, "timeout")
				else:
					if get_setting("auto"):
						timer.start(get_setting("auto_wait_time"))
						yield(timer, "timeout")
					else:
						yield(self, "_continue")#add timer for auto
			"continue", "c", "cont":
				if segment.value != "":
					timeline.handle_branch(id, segment.value)
				else:
					timeline.next()
			var option:
				if option:
					settings_override[option] = segment.value
	_segment += 1
	is_active = false


func _on_rollback(_res: Resource, id: String) -> void:
	if _history:
		if !_future:
			_future.append(_history.pop_back())
		if _history and _history[-1].id == id:
			var event = _history.pop_back()
			_future.append(event)
			text_label.bbcode_text = ""
			current_event = {}
			for i in event.segments:
				_handle_segment(i, id, true)


func _on_rollforward(_res: Resource, event: Dictionary, fast:= false) -> void:
	if _future:
		if !_history:
			_history.append(_future.pop_back())
		if _future and _future[-1].id == event.id:
			var item = _future.pop_back()
			text_label.bbcode_text = ""
			if fast:
				for i in item.segments.size():
					if _future or i < _segment:
						_handle_segment(item.segments[i], event.event, true if _future.size() > 1 else false)
					else:
						current_event = item
			else:
				_segment = 0
				current_event = event
			_history.append(event)


func _save() -> Dictionary:
	var state = {}
	state["history"] = _history
	state["future"] = _future
	state["queue"] = _queue
	state["settings"] = settings_override
	return state


func _load(state: Dictionary):
	state = Settings.states[_to_string()]
	_history = state.get("history", [])
	_future = state.get("future", [])
	_queue = state.get("queue", [])
	settings_override = state.get("settings", {})

