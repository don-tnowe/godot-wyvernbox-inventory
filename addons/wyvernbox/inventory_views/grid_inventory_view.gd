tool
class_name GridInventoryView, "res://addons/wyvernbox/icons/grid_inventory.png"
extends InventoryView

# How many cells this inventory spans horizontally.
export var width := 12 setget _set_grid_width
# How many cells this inventory spans vertically.
export var height := 8 setget _set_grid_height
# The width of the border around the inventory's cells.
export var border_width := 1.0 setget _set_border_width


func _set_cell_size(v):
	._set_cell_size(v)


func _set_grid_width(v):
	width = v
	_regenerate_view()


func _set_grid_height(v):
	height = v
	_regenerate_view()


func _set_border_width(v):
	border_width = v
	_regenerate_view()


func _set_inventory(v):
	width = v.get_width()
	height = v.get_height()
	._set_inventory(v)


func _ready2():
	_set_inventory(GridInventory.new(width, height))


func _regenerate_view():
	if !is_inside_tree(): return
	if item_scene == null: return
	
	$"Viewport/Cell".rect_size = cell_size
	$"Viewport".size = cell_size
	
	$"BG".rect_position = Vector2(border_width, border_width)
	var new_size := Vector2(border_width * 2, border_width * 2) + cell_size * Vector2(width, height)
	rect_min_size = new_size
	rect_size = new_size
	$"Border".rect_size = new_size
	$"BG".rect_size = new_size - 2 * Vector2(border_width, border_width)

# Returns the position of the cell clicked from `pos`.
# `item`'s size is used for position correction.
func global_position_to_cell(pos : Vector2, item : ItemStack) -> Vector2:
	return (Vector2(
		(pos.x - rect_global_position.x - border_width) / cell_size.x,
		(pos.y - rect_global_position.y - border_width) / cell_size.y
	) - item.item_type.get_size_in_inventory() * 0.5).round()


func _position_item(node : Control, item_stack : ItemStack):
	node.rect_position = cell_size * item_stack.position_in_inventory + Vector2(border_width, border_width)
