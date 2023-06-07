extends Label


var item_stack : ItemStack: set = _set_item_stack


func _set_item_stack(v : ItemStack):
	item_stack = v
	if !is_inside_tree(): await self.ready

	text = v.get_name()
	var color = v.extra_properties.get("back_color", Color.GRAY)
	self_modulate = color
	color.a *= 0.5
	$"Rect/Border".self_modulate = color

	if v.count != 1:
		text += " (" + str(v.count) + ")"

	if visible:
		hide()
		show()


func get_bounding_rect():
	return $"Rect".get_rect()
