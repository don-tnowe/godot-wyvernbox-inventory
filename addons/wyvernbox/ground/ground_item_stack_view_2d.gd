tool
class_name GroundItemStackView2D, "res://addons/wyvernbox/icons/item_stack_view_2d.png"
extends Area2D

signal name_clicked()

export(Resource) var item_type setget _set_item_type
export var item_count := 1 setget _set_item_count
export var item_extra : Dictionary setget _set_item_extra

export var spawn_jump_length_range := Vector2(48.0, 96.0)
export var filter_hidden_color := Color(0.5, 0.5, 0.5, 0.5)

var filter_hidden := false setget _set_filter_hidden
var item_stack : ItemStack
var jump_tween : SceneTreeTween

var item_affixes := [] setget _set_item_affixes


func _set_item_type(v):
	item_type = v
	_update_stack()


func _set_item_count(v):
	item_count = v
	_update_stack()


func _set_item_extra(v):
	item_extra = v
	_update_stack()


func _set_item_affixes(v):
	item_affixes = v
	_update_stack()


func _set_filter_hidden(v):
	filter_hidden = v
	modulate = filter_hidden_color if v else Color.white


func set_stack(stack):
	item_type = stack.item_type
	item_count = stack.count
	item_extra = stack.extra_properties
	item_affixes = stack.name_with_affixes
	_update_stack()


func _ready():
	_update_stack()
	if !Engine.editor_hint:
		jump_to_pos(position + Vector2(
				rand_range(spawn_jump_length_range.x, spawn_jump_length_range.y),
				0
		).rotated(randf() * TAU))


func jump_to_pos(pos):
	jump_tween = create_tween()
	jump_tween.tween_property(
		self, "position",
		pos, 0.5
	)


func skip_spawn_animation():
	jump_tween.kill()
	$"Anim".advance(3600.0)


func _update_stack():
	if item_type == null: return
	if !is_inside_tree(): yield(self, "ready")

	item_stack = ItemStack.new(item_type, item_count, item_extra)
	item_stack.name_with_affixes = item_affixes
	$"VisItem/Icon".texture = item_type.texture
	if !Engine.editor_hint:
		$"Label/Label".text = item_stack.get_name()
		
	var color = item_extra.get("back_color", Color.gray)
	$"Label/Label".self_modulate = color
	$"VisItem/Glow".modulate = color
	color.a *= 0.5
	$"Label/Label/Rect/Border".self_modulate = color

	if item_count != 1:
		$"Label/Label".text += " (" + str(item_count) + ")"


func try_pickup(into_inventory):
	var deposited_count = into_inventory.try_add_item(item_stack)
	item_count -= deposited_count
	if item_count <= 0:
		queue_free()


func _on_name_gui_input(event : InputEvent):
	if event is InputEventMouseButton && event.is_pressed() && event.button_index == BUTTON_LEFT:
		emit_signal("name_clicked")
		$"Label/Label".force_drag(0, null)

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			emit_signal("name_clicked")
		
		var tt = get_tree().get_nodes_in_group("tooltip")[0]
		tt.display_item(item_stack, $"HoverRect", false)
		if !Input.is_action_pressed("inventory_more"):
			tt.hide()


func _on_HoverRect_mouse_exited():
	if !Input.is_action_pressed("inventory_less"):
		$"Label/Label".hide()
		get_tree().get_nodes_in_group("tooltip")[0]._on_ground_item_released()


func _on_HoverRect_mouse_entered():
	if !filter_hidden && !$"Label/Label".visible:
		$"Label/Label".show()
		$"Label".position = Vector2(0, -2)
