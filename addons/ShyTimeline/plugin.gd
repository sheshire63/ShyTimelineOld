tool
extends EditorPlugin


var timeline_editor: Control = load("res://addons/ShyTimeline/Editor/TimelineEditor.tscn").instance()
var timeline_image: Texture = preload("res://addons/ShyTimeline/Icons/Timeline.png")
var autoloads = {
	"Settings" : "res://addons/ShyTimeline/Globals/Settings.gd",
	"Variables" : "res://addons/ShyTimeline/Globals/Vars.gd",
	"Saves" : "res://addons/ShyTimeline/Globals/Saves.gd",
}


func _enter_tree() -> void:
	get_editor_interface().get_editor_viewport().add_child(timeline_editor)
	for i in autoloads:
		add_autoload_singleton(i , autoloads[i])
	for i in get_node("/root/Settings").settings:
		add_setting(i, get_node("/root/Settings").settings[i])
	make_visible(false)
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
	for i in get_node("/root/Settings").settings:
		remove_setting(i)
	ProjectSettings.save()


func _exit_tree() -> void:
	timeline_editor.queue_free()
	for i in autoloads:
		remove_autoload_singleton(i)


func make_visible(visible: bool) -> void:
	if timeline_editor:
		timeline_editor.visible = visible


func has_main_screen():
	return true


func get_plugin_name():
	return "Timeline"


func get_plugin_icon():
	return timeline_image


func handles(object: Object) -> bool:
	return object is Timeline


func edit(object: Object) -> void:
	if object is Timeline:
		timeline_editor.timeline = object.timeline_res
		if get_editor_interface().is_playing_scene() and timeline_editor.visible == false:
			get_editor_interface().set_main_screen_editor("Script")
