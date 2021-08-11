@tool
extends GraphNode


signal request_name_change


@onready var label = $HBoxContainer/Label


var event :Resource:
	set(new):
		event = new
		for i in event.next_events:
			if int(i) == 0:
				continue
			add_child(event.create_control(int(i)))
			set_slot(int(i), false, 0, 0, true, 0, Color.WHITE)


func _on_Node_offset_changed() -> void:
	if event:
		event.pos = position_offset


func _on_Label_text_entered(new_text: String) -> void:
	if name != new_text:
		emit_signal("request_name_change", new_text)


func _on_Label_focus_exited() -> void:
	label.text = name


func _on_Node_renamed() -> void:
	if label.text != name:
		label.text = name


func _on_ButtonAdd_pressed() -> void:
	var slot = event.next_events.size()
	event.next_events[slot] = []
	add_child(event.create_control(slot))
	set_slot(slot, false, 0, 0, true, 0, Color.WHITE)


func _on_ButtonRemove_pressed() -> void:
	var slot = event.next_events.size() - 1
	if slot >= 1:
		var child = get_children()[slot]
		child.queue_free()
		set_slot(slot, false, 0, 0, false, 0, 0)
		event.next_events.erase(slot)
		event.slot_removed(slot)
		await child.tree_exited
		rect_size = rect_min_size



