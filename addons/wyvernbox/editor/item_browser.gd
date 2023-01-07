tool
extends PopupPanel

onready var folder_list : Tree = $"Box/Box/FolderList"
onready var item_list : ItemList = $"Box/Panel/Box/Margins/ItemList"
onready var path_text : Label = $"Box/Panel/Box/ItemPath"

var plugin : EditorPlugin

var items_by_dir := {}
var folders_hidden := {}
var paths_in_list := []
var filter := ""
var tree_root : TreeItem


func _ready():
	if get_viewport().get_parent() != null:
		return

	tree_root = folder_list.create_item()
	tree_root.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	tree_root.set_text(0, "All Folders")
	tree_root.set_checked(0, true)
	_scan_item_folders()
	_fill_item_list()


func initialize(editor_plugin : EditorPlugin):
	plugin = editor_plugin
	var settings = editor_plugin.get_editor_interface().get_editor_settings()
	rect_size *= editor_plugin.get_editor_interface().get_editor_scale()


func _scan_item_folders():
	var dir = Directory.new()
	var folder_queue = []
	var cur_folder = "res://"
	while true:
		dir.open(cur_folder)
		dir.list_dir_begin(true, true)
		while true:
			var cur_item = dir.get_next()
			if cur_item == "":
				break

			if dir.dir_exists(cur_folder + cur_item):
				folder_queue.append(cur_folder + cur_item + "/")
			
			elif cur_item.ends_with(".tres"):
				var loaded = load(cur_folder + cur_item)
				if loaded is ItemType || loaded is ItemGenerator:
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

	for k in items_by_dir:
		if folders_hidden.has(k):
			continue

		for x in items_by_dir[k]:
			if filter != "" && x.resource_path.find(filter) == -1 && x.resource_name.find(filter) == -1:
				continue

			item_list.add_item(
				x.resource_name if x.resource_name != "" else x.resource_path.get_file().get_basename(),
				x.texture
			)
			paths_in_list.append(x.resource_path)

	item_list.hide()
	item_list.show()
	item_list.fixed_column_width = item_list.rect_size.x / floor(item_list.rect_size.x / item_list.fixed_column_width)


func _on_item_list_gui_input(event : InputEvent):
	if !event is InputEventMouse: return

	var index = item_list.get_item_at_position(event.position, true)
	if index == -1: return

	if event is InputEventMouseMotion:
		var item = load(paths_in_list[index])
		path_text.text = item.resource_path
		path_text.self_modulate = Color.white
		if item is ItemGenerator:
			path_text.self_modulate = Color.gold
	
	elif event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT:
		var drag_preview = Label.new()
		drag_preview.text = paths_in_list[index]
		call_deferred("force_drag", {"files" : [paths_in_list[index]], "type" : "files"}, drag_preview)


func _on_filter_text_changed(new_text : String):
	filter = new_text
	_fill_item_list()


func _on_folder_list_item_activated():
	_on_folder_list_item_selected()


func _on_folder_list_item_selected():
	var clicked_item = folder_list.get_selected()
	var now_checked = !clicked_item.is_checked(0)

	if clicked_item == tree_root:
		var cur_child = clicked_item.get_children()
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
		var cur_child = tree_root.get_children()
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
