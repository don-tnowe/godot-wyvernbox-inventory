extends Node


export var item_scene : PackedScene = load("res://addons/wyvernbox/ground/ground_item_stack_view_2d.tscn")


func load_from_array(array : Array):
	var new_node : Node
	for x in array:
		new_node = item_scene.instance()
		add_child(new_node)
		new_node.item_type = load(x["type"])
		new_node.item_count = x["count"]
		new_node.item_extra = x["extra"]
		new_node.global_translation = x["position"]


func to_array():
	var array = get_children()
	for i in array.size():
		array[i] = {
			"type" : array[i].item_type.resource_path,
			"count" : array[i].item_count,
			"extra" : array[i].item_extra,
			"position" : (array[i].global_position if (array[i] is Node2D) else array[i].global_translation)
		}


func align_labels():
	var nodes = get_children()
	if !Input.is_action_pressed("inventory_less"):
		for x in nodes:
			x.get_node("Label/Label").hide()

		return

	var rects = []
	var screen_rect = get_viewport().get_visible_rect().grow(200)
	rects.resize(nodes.size())

	for i in nodes.size():
		var cur_label_rect = nodes[i].get_node("Label/Label/Rect")
		cur_label_rect.get_parent().hide()
		
		var rect = Rect2(
			nodes[i].global_position.snapped(Vector2(1, cur_label_rect.rect_size.y)),
			cur_label_rect.rect_size
		)
		rect.size.y -= 1
		rect.position -= cur_label_rect.rect_size * Vector2(0.5, 1.5)
		if screen_rect.intersects(rect):
			rect = _move_to_free_space(rect, rects, cur_label_rect.rect_size.y)

		rects[i] = rect
		cur_label_rect.get_parent().show()
		nodes[i].get_node("Label").global_position = (
			rect.position
			+ rect.size * 0.5
			+ Vector2(0, cur_label_rect.rect_size.y)
		)


func _move_to_free_space(rect : Rect2, label_rects : Array, upwards_step : float) -> Rect2:
	var touches_any = true
	while touches_any:
		touches_any = false
		for x in label_rects:
			if x == null: break
			if x == rect:
				continue
			
			if x.intersects(rect):
				rect.position.y -= upwards_step
				touches_any = true
				break
	
	return rect


func _unhandled_input(event):
	if event.is_echo(): return
	if event.is_action("inventory_less"):
		align_labels()
		align_labels()  # Can't figure why it doesn't work the first time
