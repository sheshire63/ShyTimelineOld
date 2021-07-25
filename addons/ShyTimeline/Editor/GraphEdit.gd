extends GraphEdit
tool

const NODE_FOLDER = "res://addons/ShyTimeline/Events"


var node_menu := PopupMenu.new()
var node_types := []
var timeline: Resource = load("res://addons/ShyTimeline/TimelineRes.gd").new()
const NODE := preload("res://addons/ShyTimeline/Editor/NodeTemplate.tscn")


func _ready() -> void:
	add_child(node_menu)
	node_menu.connect("id_pressed", self, "_on_menu_item_pressed")
	var dir = Directory.new()
	if dir.dir_exists(NODE_FOLDER):
		dir.open(NODE_FOLDER)
		dir.list_dir_begin(true)
		var file: String = dir.get_next()
		while file != "":
			if file.get_extension() == "gd":
				node_types.append(load(NODE_FOLDER + "/" + file))
				node_menu.add_item(file)
			elif dir.dir_exists(file):
				pass #add submenu?
			file = dir.get_next()


func load_timeline(new) -> void:
	timeline = new
	for i in timeline.events:
		var node = _create_node(timeline.events[i])
		node.offset = timeline.events[i].pos
		add_child(node)
		node.name = i
		for j in node.event.next_events:
			for k in node.event.next_events[j]:
				call_deferred("connect_node", i, j, k, 0)


func _on_node_change_name_request(new: String, sender) -> void:
	var old = sender.name
	var event = timeline.events[old]
	new = timeline.add_event(sender, new)
	timeline.events.erase(old)
	for i in get_connection_list():
		if i.from == old:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)
			connect_node(new, i.from_port, i.to, i.to_port)
		if i.to == old:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)
			connect_node(i.from, i.from_port, new, i.to_port)


func _on_menu_item_pressed(id: int) -> void:
	var event = node_types[id].new()
	var node = _create_node(event)
	node.offset = (scroll_offset + get_local_mouse_position()) / zoom
	add_child(node)
	timeline.add_event(event)


func _on_GraphEdit_connection_from_empty(to: String, to_slot: int, position: Vector2) -> void:
	pass # Replace with function body.


func _on_GraphEdit_connection_request(from: String, from_slot: int, to: String, to_slot: int) -> void:
	connect_node(from, from_slot, to, to_slot)
	timeline.events[from].next_events[from_slot].append(to)


func _on_GraphEdit_connection_to_empty(from: String, from_slot: int, position: Vector2) -> void:
	pass # Replace with function body.


func _on_GraphEdit_copy_nodes_request() -> void:
	pass # Replace with function body.


func _on_GraphEdit_delete_nodes_request() -> void:
	var nodes := []
	for i in get_children():
		if i is GraphNode and i.selected:
			nodes.append(i.name)
			timeline.events.erase(i.name)
			i.queue_free()
	for i in get_connection_list():
		if i.to in nodes:
			timeline.events[i.from].next_events[i.from_port].erase(i.to)
			disconnect_node(i.from, i.from_port, i.to, i.to_slot)


func _on_GraphEdit_disconnection_request(from: String, from_slot: int, to: String, to_slot: int) -> void:
	disconnect_node(from, from_slot, to, to_slot)
	timeline.events[from].next_events[from_slot].erase(to)


func _on_GraphEdit_duplicate_nodes_request() -> void:
	pass # Replace with function body.


func _on_GraphEdit_node_selected(node: Node) -> void:
	if Engine.editor_hint:
		EditorPlugin.new().get_editor_interface().edit_resource(node.event)


func _on_GraphEdit_node_unselected(node: Node) -> void:
	pass # Replace with function body.


func _on_GraphEdit_paste_nodes_request() -> void:
	pass # Replace with function body.


func _on_GraphEdit_popup_request(position: Vector2) -> void:
	node_menu.popup(Rect2(position, node_menu.rect_size))


func clear() -> void:
	for i in get_children():
		if i is GraphNode:
			i.queue_free()
	clear_connections()


func _on_node_slot_updated(slot: int, node: GraphNode) -> void:
	if !node.is_slot_enabled_right(slot):
		for i in node.event.next_events[slot]:
			disconnect_node(node.name, slot, i, 0)


func _create_node(event: Resource) -> GraphNode:
	var node = NODE.instance()
	node.connect("request_name_change", self, "_on_node_change_name_request", [node])
	node.connect("slot_updated", self, "_on_node_slot_updated", [node])
	node.event = event
	return node
