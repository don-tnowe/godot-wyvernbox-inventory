@icon("res://addons/wyvernbox/icons/item_stack_view.png")
class_name ItemStackView
extends Control

## The displayed [ItemStack].
var stack : ItemStack


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

## Sets the displayed stack.
## [code]unit_size[/code] is the width of the inventory's cells.
## [code]show_background[/code], if not disabled, will make this [ItemStackView] show the stack's "back_color" extra property as background.
func update_stack(item_stack, unit_size, show_background = true):
	stack = item_stack
	if item_stack == null: return

	item_stack.display_texture($"Crop/Texture2D")
	$"Crop/Texture2D".scale = Vector2.ONE * item_stack.item_type.texture_scale
	size = unit_size * item_stack.item_type.get_size_in_inventory()

	$"Count".text = str(item_stack.count)
	$"Count".visible = item_stack.count != 1
	$"Rarity".visible = show_background
	$"Rarity".self_modulate = item_stack.extra_properties.get(&"back_color", Color.TRANSPARENT)


func _on_mouse_entered():
	get_tree().call_group(&"tooltip", &"display_item", stack, self)


func _on_mouse_exited():
	get_tree().call_group(&"tooltip", &"hide")
