@icon("res://addons/wyvernbox/icons/item_stack_view.png")
class_name ItemStackView
extends Control

## A view into an [ItemStack] inside an inventory.

## The displayed [ItemStack].
var stack : ItemStack


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_mouse_entered)

## Sets the displayed stack. [br]
## [code]unit_size[/code] is the width of the inventory's cells. [br]
## [code]show_background[/code], if not disabled, will make this [ItemStackView] show the stack's "back_color" extra property as background.
func update_stack(item_stack, unit_size, show_background = true):
	stack = item_stack
	if item_stack == null: return

	item_stack.display_texture($"%Texture")
	$"%Texture".scale = Vector2.ONE * item_stack.item_type.texture_scale
	size = unit_size * item_stack.item_type.get_size_in_inventory()

	$"%Count".text = str(item_stack.count)
	$"%Count".visible = item_stack.count != 1

	var back := get_node_or_null("%BackColor")
	if back != null:
		back.visible = show_background
		back.self_modulate = item_stack.extra_properties.get(&"back_color", Color.TRANSPARENT)

## If [code]true[/code], shows the tooltip with this item. Otherwise, hides it.
func tooltip_set_visible(status : bool):
	var tt := InventoryTooltip.get_instance()
	if !is_instance_valid(tt):
		return

	if status:
		tt.display_item(stack, self)
	
	else:
		tt.hide()


func _on_mouse_entered():
	tooltip_set_visible(true)


func _on_mouse_exited():
	tooltip_set_visible(false)
