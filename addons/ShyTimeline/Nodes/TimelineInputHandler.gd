extends BaseHandler
tool

class_name InputHandler


signal input_confirmed()


export var int_control : PackedScene
export var float_control : PackedScene
export var bool_control : PackedScene
export var string_control : PackedScene
export var confirm_button : NodePath

var int_property_path: NodePath = ".:value"
var float_property_path: NodePath = ".:value"
var bool_property_path: NodePath = ".:enabled"
var string_property_path: NodePath = ".:text"
var int_value_changed_signal := "value_changed"
var float_value_changed_signal := "value_changed"
var bool_value_changed_signal := "toggled"
var string_value_changed_signal := "text_changed"

export var wait_for_input := true
export(NodePath) var time_bar_path

onready var container = get_parent()
var timer := Timer.new()
var is_active := false
var time_bar: Range

var inputs := {}


func _get_property_list() -> Array:
	var list = []
	if int_control:
		list.append({
			"name": "int_property_path",
			"type": TYPE_STRING
		})
		list.append({
			"name": "int_value_changed_signal",
			"type": TYPE_STRING
		})
	if float_control:
		list.append({
			"name": "float_property_path",
			"type": TYPE_STRING
		})
		list.append({
			"name": "float_value_changed_signal",
			"type": TYPE_STRING
		})
	if bool_control:
		list.append({
			"name": "bool_property_path",
			"type": TYPE_STRING
		})
		list.append({
			"name": "bool_value_changed_signal",
			"type": TYPE_STRING
		})
	if string_control:
		list.append({
			"name": "string_property_path",
			"type": TYPE_STRING
		})
		list.append({
			"name": "string_value_changed_signal",
			"type": TYPE_STRING
		})
	return list


func _get_configuration_warning() -> String:
	if not get_parent() is Container:
		return "needs to be child of a Container"
	return ""


func _ready() -> void:
	if Engine.editor_hint:
		return
	if time_bar_path:
		time_bar = get_node(time_bar_path)
	else:
		time_bar = ProgressBar.new()
		time_bar.percent_visible = false
		container.call_deferred("add_child", time_bar)
	time_bar.visible = false
	timer.one_shot = true
	add_child(timer)
	_clear_controls()

#...
func _on_handle_event(event: Resource, event_id: String, id: int) -> void:
	if event.get_event_type() == "Input":
		is_active = true
		#how to handle labels?
		#	option to have the label as part of control
		for i in event.inputs:
			var control: Control
			var property_path: NodePath
			var value_changed_signal: String
			match event.inputs[i].type:
				TYPE_BOOL:
					control = bool_control.instance() if bool_control else CheckButton.new()
					property_path = bool_property_path
					value_changed_signal = bool_value_changed_signal
				TYPE_INT:
					if int_control:
						control = int_control.instance()
					else:
						control = SpinBox.new()
						control.rounded = true
					property_path = int_property_path
					value_changed_signal = int_value_changed_signal
				TYPE_REAL:
					control = float_control.instance() if float_control else SpinBox.new()
					property_path = float_property_path
					value_changed_signal = float_value_changed_signal
				TYPE_STRING:
					control = string_control.instance() if string_control else LineEdit.new()
					property_path = string_property_path
					value_changed_signal = string_value_changed_signal
			container.add_child(control)
			control = control.get_node(property_path)
			control.set(property_path.get_concatenated_subnames(), event.inputs[i].value)
			control.connect(value_changed_signal, self, "_on_value_changed", [event.inputs[i]])
			
			var button
			if !confirm_button:
				button = Button.new()
				button.text = "Confirm"
				container.add_child(button)
			else:
				button = get_node(confirm_button)
			button.connect("pressed", self, "_on_input_confirmed")
		
		if event.input_time > 0.0:
			timer.start(event.choose_time)
			time_bar.visible = true
			yield(timer, "timeout")
			time_bar.visible = false
		elif wait_for_input: #to setting
			yield(self, "input_confirmed")
		if is_active:
			for i in inputs:
				Variables.variables[i] = inputs[i]
			timeline.event_handled(event_id)
		_clear_controls()
		is_active = false


func _on_input_confirmed() -> void:
	if !timer.is_stopped():
		timer.stop()
	emit_signal("input_confirmed")


func _clear_controls() -> void:
	for i in container.get_children():
		if i is Control and i != time_bar:
			i.visible = false
			i.queue_free()
	if confirm_button:
		get_node(confirm_button).disconnect("pressed", self, "_on_input_confirmed")


func _process(_delta: float) -> void:
	if !timer.is_stopped():
		time_bar.value = (timer.wait_time - timer.time_left) / timer.wait_time * 100


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_input_confirmed()


func _on_rollback(_res: Resource, id: String) -> void:
	pass#stop event


func _on_rollforward(_res: Resource, event: Dictionary, fast:= false) -> void:
	pass#handle normaly?


func _save() -> Dictionary:
	return {}


func _load(save: Dictionary):
	pass


func _on_value_changed(new, input: Dictionary) -> void:
	inputs[input.variable] = new if input.type != TYPE_INT else int(new)
