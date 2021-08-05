extends GraphEdit
tool

const NODE_FOLDER = "res://addons/ShyTimeline/Events"
const DEFAULT_TIMELINE = "res://addons/ShyTimeline/TimelineRes.gd"

var node_menu := PopupMenu.new()
var node_types := []
var timeline: Resource
var _connect_to := {}


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
				pass #todo add submenu
			file = dir.get_next()
	if !Engine.editor_hint:
		timeline = load(DEFAULT_TIMELINE).new()


func load_timeline(new) -> void:
	timeline = new
	_add_events(timeline.events)


func _add_events(events: Dictionary, to_timeline := false) -> void:
	var names = {}
	if to_timeline:
		for i in events:
				if i in timeline.events:
					names[i] = timeline.add_event(events[i], i)
		for i in events:
			for j in events[i].next_events:
				for k in events[i].next_events[j]:
					if k in names:
						events[i].next_events[j][names[k]] = events[i].next_events[j][k]
						events[i].next_events[j].erase([k])
	for i in events:
		var node = _create_node(events[i])
		node.offset = events[i].pos
		if to_timeline:
			 node.offset += Vector2(128, 128)
		add_child(node)
		node.name = names.get(i, i)
		for j in node.event.next_events:
			for k in node.event.next_events[j]:
				call_deferred("connect_node", node.name, int(j), k, 0)


func _on_node_change_name_request(new: String, sender) -> void:
	var old = sender.name
	var event = timeline.events[old]
	new = timeline.add_event(sender.event, new)
	timeline.events.erase(old)
	sender.name = new
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
	node.name = timeline.add_event(event)
	if _connect_to:
		_on_connection_request(
				_connect_to.get("from", node.name),
				_connect_to.get("from_slot", 0),
				_connect_to.get("to", node.name),
				_connect_to.get("to_slot", 0))


func _on_connection_from_empty(to: String, to_slot: int, position: Vector2) -> void:
	_connect_to = {"to": to, "to_slot": to_slot}
	node_menu.popup(Rect2(position, node_menu.rect_size))


func _on_connection_request(from: String, from_slot: int, to: String, to_slot: int) -> void:
	connect_node(from, from_slot, to, to_slot)
	timeline.events[from].next_events[from_slot].append(to)


func _on_connection_to_empty(from: String, from_slot: int, position: Vector2) -> void:
	_connect_to = {"from": from, "from_slot": from_slot}
	node_menu.popup(Rect2(position, node_menu.rect_size))


func _on_copy_nodes_request() -> void:
	var data = {}
	for i in get_children():
		if i is GraphNode and i.selected:
			data[i.name] = i.event.save()
	OS.clipboard = to_json(data)
	#this converts dictionary keys to strings and all numbers to floats.
	#also objects(textures/images/sounds/...) will not be copied
	#use a locale var instead and add export button to the menu

func _on_delete_nodes_request() -> void:
	var nodes := []
	for i in get_children():
		if i is GraphNode and i.selected:
			#we dont call _delete_node to check the connection list only once
			#is  this worth it performance wise?
			nodes.append(i.name)
			timeline.events.erase(i.name)
			i.queue_free()
	for i in get_connection_list():
		if i.to in nodes:
			timeline.events[i.from].next_events[i.from_port].erase(i.to)
		if i.to in nodes or i.from in nodes:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)


func _delete_node(node:GraphNode) -> void:
	timeline.events.erase(node.name)
	node.queue_free()
	for i in get_connection_list():
		if i.to == node.name:
			timeline.events[i.from].next_events[i.from_port].erase(i.to)
		if i.to == node.name or i.from == node.name:
			disconnect_node(i.from, i.from_port, i.to, i.to_port)


func _on_disconnection_request(from: String, from_slot: int, to: String, to_slot: int) -> void:
	disconnect_node(from, from_slot, to, to_slot)
	timeline.events[from].next_events[from_slot].erase(to)


func _on_duplicate_nodes_request() -> void:
	var data = {}
	for i in get_children():
		if i is GraphNode and i.selected:
			data[i.name] = i.event.duplicate(true)
	_add_events(data, true)


func _on_node_selected(node: Node) -> void:
	if Engine.editor_hint:
		EditorPlugin.new().get_editor_interface().edit_resource(node.event)


func _on_node_unselected(node: Node) -> void:
	pass # Replace with function body.


func _on_paste_nodes_request() -> void:
	var data: Dictionary = parse_json(OS.clipboard)
	var events := {}
	if data:
		for i in data:
			for j in node_types:
				if j.get_event_type() == data[i].type:
					var tmp = j.new()
					tmp.load(data[i])
					events[i] = tmp
					break
		_add_events(events, true)


func _on_popup_request(position: Vector2) -> void:
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
	var node = event.get_node()
	node.connect("request_name_change", self, "_on_node_change_name_request", [node])
	node.connect("slot_updated", self, "_on_node_slot_updated", [node])
	node.connect("close_request", self, "_delete_node", [node])
	node.event = event
	return node


func _on_PopupMenu_popup_hide() -> void:
	_connect_to = {}


