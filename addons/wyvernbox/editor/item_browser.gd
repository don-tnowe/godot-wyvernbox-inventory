@tool
extends Panel

@export var type_colors := {
	ItemType : Color.WHITE,
	ItemGenerator : Color.GOLD,
	ItemPattern : Color.DARK_TURQUOISE,
}
@export var item_list_column_width := 48.0

@onready var folder_list : Tree = $"Box/Box/FolderList"
@onready var item_list : ItemList = $"Box/Panel/Box/ItemList"
@onready var path_text : Label = $"Box/Panel/Box/ItemPath"
@onready var filter_text : LineEdit = $"Box/Panel/Box/Filter"

var plugin : EditorPlugin

var items_by_dir := {}
var folders_hidden := {}
var paths_in_list := []
var filter := ""
var tree_root : TreeItem
var allowed_types := []


func initialize(plugin : EditorPlugin, types_allowed : Array = [ItemType, ItemGenerator, null]):
	self.plugin = plugin
	tree_root = folder_list.create_item()
	tree_root.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	tree_root.set_text(0, "All Folders")
	tree_root.set_checked(0, true)

	var checkboxes = $"Box/Panel/Box/TypeFilter".get_children()
	allowed_types = [
		ItemType in types_allowed,
		ItemGenerator in types_allowed,
		ItemPattern in types_allowed,
	]
	for i in checkboxes.size():
		checkboxes[i].button_pressed = allowed_types[i]
		checkboxes[i].toggled.connect(Callable(self, &"_on_type_filter_toggled").bind(i))

	var settings = plugin.get_editor_interface().get_editor_settings()
	size *= plugin.get_editor_interface().get_editor_scale()
	visibility_changed.connect(_on_visibility_changed)

	var panel_style := get_theme_stylebox(&"panel", &"Tree")
	filter_text.add_theme_stylebox_override(&"normal", panel_style)
	item_list.add_theme_stylebox_override(&"panel", panel_style)

	_scan_item_folders()
	_fill_item_list()


func _scan_item_folders():
	items_by_dir.clear()
	for x in tree_root.get_children():
		x.free()

	var folder_queue := []
	var cur_folder := "res://"
	var dir : DirAccess
	while true:
		dir = DirAccess.open(cur_folder)
		for cur_item in dir.get_directories():
			folder_queue.append(cur_folder.path_join(cur_item).path_join(""))

		for cur_item in dir.get_files():
			if cur_item.ends_with(".tres"):
				var loaded = load(cur_folder.path_join(cur_item))
				if loaded is ItemLike:
					if !items_by_dir.has(cur_folder):
						_add_item_folder(cur_folder)

					items_by_dir[cur_folder].append(loaded)

		if folder_queue.size() == 0:
			break
		
		else:
			cur_folder = folder_queue.pop_back()


func _add_item_folder(path : String):
	var item = folder_list.create_item()
	item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	item.set_text(0, path.get_base_dir().get_file())
	item.set_metadata(0, {"path" : path})
	item.set_checked(0, true)
	items_by_dir[path] = []


func _fill_item_list():
	item_list.clear()
	paths_in_list.clear()

	var item_list_class := load("res://addons/wyvernbox/editor/inspector_item_list.gd")
	var label_color : Color
	var type_colors_keys := type_colors.keys()
	var type_allowed : bool
	for k in items_by_dir:
		if folders_hidden.has(k):
			continue

		for x in items_by_dir[k]:
			type_allowed = true
			for i in type_colors_keys.size():
				if item_list_class.instance_has_recursive(x, type_colors_keys[i]):
					label_color = type_colors[type_colors_keys[i]]
					if !allowed_types[i]:
						type_allowed = false
						continue

			if !type_allowed:
				continue

			if filter != "" && x.resource_path.find(filter) == -1 && x.resource_name.find(filter) == -1:
				continue

			item_list.add_item(
				x.resource_name if x.resource_name != "" else x.resource_path.get_file().get_basename(),
				x.texture
			)
			item_list.set_item_custom_fg_color(item_list.get_item_count() - 1, label_color)
			paths_in_list.append(x.resource_path)

	item_list.hide()
	item_list.show()
	item_list.fixed_column_width = item_list.size.x / ceil(item_list.size.x / item_list_column_width)


func _on_visibility_changed():
	if visible:
		if get_child_count() == 0: await ready
		filter_text.grab_focus()


func _on_item_list_gui_input(event : InputEvent):
	if !event is InputEventMouse: return

	var index = item_list.get_item_at_position(event.position, true)
	if index == -1: return

	if event is InputEventMouseMotion:
		var item = load(paths_in_list[index])
		path_text.text = item.resource_path
		for k in type_colors:
			if k.instance_has(item):
				path_text.self_modulate = type_colors[k]

	elif event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		var drag_preview = Label.new()
		drag_preview.text = paths_in_list[index]
		drag_preview.size.x = 9999.0
		item_list.force_drag.call_deferred({&"files" : [paths_in_list[index]], &"type" : "files"}, drag_preview)


func _on_filter_text_changed(new_text : String):
	filter = new_text
	_fill_item_list()


func _on_folder_list_item_activated():
	_on_folder_list_item_selected()


func _on_folder_list_item_selected():
	var clicked_item = folder_list.get_selected()
	var now_checked = !clicked_item.is_checked(0)

	if clicked_item == tree_root:
		var cur_child = clicked_item.get_first_child()
		while true:
			_set_folder_hidden(cur_child, now_checked)
			cur_child = cur_child.get_next()
			if cur_child == null:
				break

	else:
		_set_folder_hidden(clicked_item, now_checked)

	_fill_item_list()


func _set_folder_hidden(tree_item, hidden):
	var path = tree_item.get_metadata(0)["path"]
	tree_item.set_checked(0, hidden)

	if hidden:
		folders_hidden.erase(path)
		var cur_child = tree_root.get_first_child()
		while true:
			if !cur_child.is_checked(0):
				tree_root.set_checked(0, false)
				break
				
			cur_child = cur_child.get_next()
			if cur_child == null:
				tree_root.set_checked(0, true)
				break

	else:
		folders_hidden[path] = true
		tree_root.set_checked(0, false)


func _on_rescan_pressed():
	_scan_item_folders()


func _on_type_filter_toggled(toggled, type_index):
	allowed_types[type_index] = toggled
	_fill_item_list()
