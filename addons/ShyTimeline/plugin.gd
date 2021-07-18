tool
extends EditorPlugin


var timeline_editor: Control = load("res://addons/ShyTimeline/Editor/TimelineEditor.tscn").instance()
var timeline_node: Script = load("res://addons/ShyTimeline/Nodes/Timeline.gd")
var handler_base: Script = load("res://addons/ShyTimeline/Nodes/TimelineBaseHandler.gd")
var handler_choice: Script = load("res://addons/ShyTimeline/Nodes/TimelineChoiceHandler.gd")
var handler_text : Script = load("res://addons/ShyTimeline/Nodes/TimelineTextHandler.gd")
var timeline_res: Script = load("res://addons/ShyTimeline/TimelineRes.gd")
var timeline_image: Texture = preload("res://addons/ShyTimeline/Icons/Timeline.png")
var setting_path := "res://addons/ShyTimeline/Globals/Settings.gd"
var variabels_path := "res://addons/ShyTimeline/Globals/Vars.gd"
var saves_path := "res://addons/ShyTimeline/Globals/Saves.gd"
#todo to dictionarys to have names and paths at the top and less code


func _enter_tree() -> void:
#	add_custom_type("Timeline" ,"Node", timeline_node, timeline_image)
#	add_custom_type("TextHandler" ,"Node", handler_text, timeline_image)
#	add_custom_type("BaseHandler" ,"Node", handler_base, timeline_image)
#	add_custom_type("ChoiceHandler" ,"Node", handler_choice, timeline_image)
	add_custom_type("TimelineRes", "Resource", timeline_res, timeline_image)
	get_editor_interface().get_editor_viewport().add_child(timeline_editor)
	add_autoload_singleton("Settings", setting_path)
	add_autoload_singleton("Variables", variabels_path)
	add_autoload_singleton("Saves", saves_path)
	
	make_visible(false)
	var settings = load(setting_path)
	for i in settings.settings:
		add_setting(i, settings.settings[i])
	ProjectSettings.save()



func add_setting(setting: String, value) -> void:
	if !ProjectSettings.has_setting("ShyTimeline/settings/" + setting):
		ProjectSettings.set_setting("ShyTimeline/settings/" + setting, value)
		ProjectSettings.set_initial_value("ShyTimeline/settings/" + setting, value)
		ProjectSettings.add_property_info({
				"name" : "ShyTimeline/settings/" + setting,
				"type" : typeof(value),
		})


func remove_setting(setting: String) -> void:
	ProjectSettings.clear("ShyTimeline/settings/" + setting)


func disable_plugin() -> void:
	for i in load(setting_path).settings:
		remove_setting(i)
	ProjectSettings.save()


func _exit_tree() -> void:
	timeline_editor.queue_free()
	remove_custom_type("Timeline")
	remove_custom_type("TimelineRes")
	remove_autoload_singleton("Variables")
	remove_autoload_singleton("Settings")
	remove_autoload_singleton("Saves")


func make_visible(visible: bool) -> void:
	if timeline_editor and !get_editor_interface().is_playing_scene():
		timeline_editor.visible = visible


func has_main_screen():
	return true


func get_plugin_name():
	return "Timeline"


func get_plugin_icon():
	return timeline_image


func handles(object: Object) -> bool:
	return object is timeline_node


func edit(object: Object) -> void:
	if object is Timeline and object.timeline_res:
		timeline_editor.timeline = object.timeline_res
