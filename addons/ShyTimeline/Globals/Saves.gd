extends Node

const save_path := "user://shytimeline/saves"

signal request_save
signal request_load_save

var settings
var variables
var states = {}


#todo add crypto
#todo create screenshot and save with same name for thumbnails and get func for it
func get_saves() -> Array:
	var saves := []
	var dir := Directory.new()
	if dir.open(save_path) == OK:
		dir.list_dir_begin(true)
		var file: String = dir.get_next()
		while file != "":
			saves.append(file)
			file = dir.get_next()
		dir.list_dir_end()
	return saves


func save(name: String, force := false) -> void:
	var file := File.new()
	var path := save_path + "/" + name
	if file.file_exists(path) and !force:
			var popup := ConfirmationDialog.new()
			popup.connect("confirmed", save, [name, true])
			add_child(popup)
			popup.popup_centered()
			await popup.modal_closed
			popup.queue_free()
			return
	emit_signal("request_save")
	if file.open(save_path, File.WRITE) == OK:
		file.store_var(settings)
		file.store_var(variables)
		file.store_var(states)
		file.close()


func laod_save(name:String) -> void:
	var file := File.new()
	var path := save_path + "/" + name
	if file.open(save_path, File.READ) == OK:
		settings = file.get_var()
		variables = file.get_var()
		states = file.get_var()
		file.close()
		emit_signal("request_load_save")
