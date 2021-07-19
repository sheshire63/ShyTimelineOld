extends BaseHandler
tool

class_name ChoiceHandler


signal button_pressed()

export var button : PackedScene
export var button_text_property := ".:text"
export(Array, NodePath) var button_overrides := []
export(NodePath) var button_container_path
export var wait_for_button_press := true
export(NodePath) var time_bar_path

var button_container
var timer := Timer.new()
var is_active := false
var time_bar: Range


func _ready() -> void:
	if Engine.editor_hint:
		return
	if button_container_path:
		button_container = get_node(button_container_path)
	else:
		var center_box = CenterContainer.new()
		center_box.set_anchors_preset(Control.PRESET_CENTER)
		button_container = VBoxContainer.new()
		var canvas = CanvasLayer.new()
		canvas.add_child(center_box)
		center_box.add_child(button_container)
		add_child(canvas)
	
	if time_bar_path:
		time_bar = get_node(time_bar_path)
	else:
		time_bar = ProgressBar.new()
		time_bar.percent_visible =false
		button_container.add_child(time_bar)
	time_bar.visible = false
	timer.one_shot = true
	add_child(timer)
	_reset_buttons()


func _on_handle_event(event: Resource, event_id: String, id: int) -> void:
	if event.get_node_type() == "ChoiceEvent":
		is_active = true
		var buttons = {}
		for i in event.choice_text.size():
			if button_overrides.size() > i and button_overrides[i]:
				buttons[i] = get_node(button_overrides[i])
				buttons[i].visible = true
			else:
				buttons[i] = button.instance() if button else Button.new()
				button_container.add_child(buttons[i])
			var text = ""
			for j in Variables.format_text(event.choice_text[i + 1], false):
				text += j.get("text", "")
			buttons[i].get_node((button_text_property as NodePath)).set(
					(button_text_property as NodePath).get_concatenated_subnames(),
					text)
			buttons[i].connect("pressed", self, "_on_button_pressed", [i + 1, event_id])
		if event.choose_time  > 0.0:
			timer.start(event.choose_time)
			time_bar.visible = true
			yield(timer, "timeout")
			timeline.event_handled(event_id)
			time_bar.visible = false
			_reset_buttons()
		elif wait_for_button_press: #to setting
			yield(self, "button_pressed")
			timeline.event_handled(event_id)
		is_active = false


func _on_button_pressed(idx: int, event: String) -> void:
	if !timer.is_stopped():
		is_active = false
		timer.stop()
	timeline.handle_branch(event, idx)
	_reset_buttons()
	emit_signal("button_pressed")


func _reset_buttons() -> void:
	for i in button_overrides:
		if i:
			i = get_node(i)
			i.disconnect("pressed", self, "_on_button_pressed")
			i.visible = false
	for i in button_container.get_children():
		if not i is Range:
			i.queue_free()


func _process(_delta: float) -> void:
	if !timer.is_stopped():
		time_bar.value = (timer.wait_time - timer.time_left) / timer.wait_time * 100


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
