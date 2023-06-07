@tool
@icon("res://addons/wyvernbox/icons/item_stack_view_2d.png")
class_name GroundItemStackView2D
extends Area2D

signal clicked()

## The [ItemType] of the displayed item.
@export var item_type: Resource: set = _set_item_type

## The count of the displayed item.
@export var item_count := 1: set = _set_item_count

## The extra properties of the displayed item - if not set, uses type's [member ItemType.default_properties].
@export var item_extra : Dictionary: set = _set_item_extra


## The modulation to apply if filtered out by [member GroundItemManager.view_filter_patterns]. [code]Color(1, 1, 1, 1)[/code] to disable.
@export var filter_hidden_color := Color(0.5, 0.5, 0.5, 0.5)


## The [member ItemStack.name_with_affixes] of the displayed item.
var item_affixes := []: set = _set_item_affixes

## [code]true[/code] if hidden by parent's [member GroundItemManager.view_filter_patterns].
var filter_hidden := false: set = _set_filter_hidden

## The [ItemStack] displayed by this node.
var item_stack : ItemStack

var _jump_tween : Tween


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


func _set_filter_hidden(v : bool):
	filter_hidden = v
	modulate = filter_hidden_color if v else Color.WHITE

## Sets the displayed [ItemStack].
func set_stack(stack : ItemStack):
	item_type = stack.item_type
	item_count = stack.count
	item_extra = stack.extra_properties
	item_affixes = stack.name_with_affixes
	_update_stack()


func _ready():
	_update_stack()


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


func get_label_rect():
	return $"Label/Label/Rect"


func _update_stack():
	if item_type == null: return
	if !is_inside_tree(): await self.ready

	item_stack = ItemStack.new(item_type, item_count, item_extra)
	item_stack.name_with_affixes = item_affixes
	$"Label/Label".item_stack = item_stack
	$"VisItem/Glow".modulate = item_extra.get("back_color", Color.GRAY)
	item_stack.display_texture($"VisItem/Icons/Icon")

## Tries to add item into [code]into_inventory[/code], freeing this node on full success.
func try_pickup(into_inventory):
	var deposited_count = into_inventory.try_add_item(item_stack)
	item_count -= deposited_count
	if item_count <= 0:
		queue_free()


func _on_name_gui_input(event : InputEvent):
	if event is InputEventMouseButton && event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
		$"Label/Label".force_drag(0, null)

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			clicked.emit()
		
		var tt = get_tree().get_nodes_in_group("tooltip")[0]
		tt.display_item(item_stack, $"HoverRect", false)
		if !Input.is_action_pressed(&"inventory_more"):
			tt.hide()


func _on_HoverRect_mouse_exited():
	if !Input.is_action_pressed(&"inventory_less"):
		set_label_visible(false)
		get_tree().get_nodes_in_group(&"tooltip")[0]._on_ground_item_released()


func _on_HoverRect_mouse_entered():
	if !filter_hidden && !$"Label/Label".visible:
		set_label_visible(true)
		$"Label".position = Vector2(0, -2)
