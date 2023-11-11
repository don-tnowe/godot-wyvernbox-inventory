@tool
@icon("res://addons/wyvernbox/icons/item_stack_view_2d.png")
class_name GroundItemStackView2D
extends Area2D

signal clicked()


## The modulation to apply if filtered out by [member GroundItemManager.view_filter_patterns]. [code]Color(1, 1, 1, 1)[/code] to disable.
@export var filter_hidden_color := Color(0.5, 0.5, 0.5, 0.5)


## [code]true[/code] if hidden by parent's [member GroundItemManager.view_filter_patterns].
var filter_hidden := false:
	set = _set_filter_hidden

## The [ItemStack] displayed by this node.
var item_stack : ItemStack:
	set = _set_stack

var _jump_tween : Tween
var _mouse_in_label := false


func _set_filter_hidden(v : bool):
	filter_hidden = v
	modulate = filter_hidden_color if v else Color.WHITE


func _set_stack(v : ItemStack):
	if v == null: return

	item_stack = v

	if !is_inside_tree(): await self.ready

	$"Label/Label".item_stack = item_stack
	$"VisItem/Glow".modulate = item_stack.extra_properties.get(&"back_color", Color.GRAY)
	item_stack.display_texture($"VisItem/Icons/Icon")


## Sets the displayed [ItemStack].
func set_stack(stack : ItemStack):
	item_stack = stack

## Hides or shows the item name label.
func set_label_visible(v : bool):
	$"Label/Label".visible = v

## Plays jump animation and moves to local position [code]pos[/code].
func jump_to_pos(pos, _upwards = null):
	_jump_tween = create_tween()
	_jump_tween.tween_property(
		self, "position",
		pos, 0.5
	)
	$"Anim".play("init")
	$"Anim".seek(0)

## Returns a random vector with length between [code]dist_min[/code] and [code]dist_max[/code].
func get_random_jump_vector(dist_min : float, dist_max : float) -> Vector2:
	return Vector2(
		randf_range(dist_min, dist_max),
		0
	).rotated(randf() * TAU)

## Interrupts the jump animation.
func skip_spawn_animation():
	if _jump_tween != null: _jump_tween.kill()
	$"Anim".advance(3600.0)

## Returns the [Control] inside the name label.
func get_label_rect() -> Control:
	return $"Label/Label/Rect"

## Tries to add item into [code]into_inventory[/code], freeing this node on full success.
func try_pickup(into_inventory : Inventory):
	var deposited_count = into_inventory.try_add_item(item_stack)
	item_stack.count -= deposited_count
	if item_stack.count <= 0:
		queue_free()

	item_stack = item_stack  # Call setter


func _on_name_gui_input(event : InputEvent):
	if event is InputEventMouseButton && event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
		$"Label/Label".force_drag(0, null)

	if event is InputEventMouseMotion:
		_mouse_in_label = true
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			clicked.emit()
		
		var tt := InventoryTooltip.get_instance()
		if !is_instance_valid(tt):
			return

		tt.display_item(item_stack, $"HoverRect", false)
		if !Input.is_action_pressed(&"inventory_more"):
			tt.hide()


func _on_HoverRect_mouse_exited():
	if Input.is_action_pressed(&"inventory_less"):
		return

	_mouse_in_label = false
	await get_tree().process_frame
	if _mouse_in_label:
		_mouse_in_label = false
		return

	set_label_visible(false)
	var tt := InventoryTooltip.get_instance()
	if is_instance_valid(tt):
		tt._on_ground_item_released()


func _on_HoverRect_mouse_entered():
	_mouse_in_label = true
	if !filter_hidden && !$"Label/Label".visible:
		set_label_visible(true)
		$"Label".position = Vector2(0, -2)


func _on_label_mouse_exited():
	_mouse_in_label = false
	await get_tree().process_frame
	if _mouse_in_label:
		_mouse_in_label = false
		return

	set_label_visible(false)
