tool
extends EditorPlugin


var inspector_plugin = load("res://addons/wyvernbox/editor/inspector_plugin.gd").new(self)


func _enter_tree():
	add_inspector_plugin(inspector_plugin)


func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
