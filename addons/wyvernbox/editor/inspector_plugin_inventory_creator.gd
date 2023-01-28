extends EditorInspectorPlugin

var property_script =	load("res://addons/wyvernbox/editor/inspector_inventory_creator.gd")

var plugin



func _init(plugin):
	self.plugin = plugin


func can_handle(object):
	return "inventory" in object


func parse_property(object, type, path, hint, hint_text, usage):
	if path != "inventory": return false
	var new_editor = property_script.new()
	add_property_editor("inventory", new_editor)
	new_editor._ready()
	return false
