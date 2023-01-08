tool
class_name GridInventoryView, "res://addons/wyvernbox/icons/grid_inventory.png"
extends InventoryView

export var height := 8 setget _set_grid_height
export var border_width := 1.0 setget _set_border_width


func _set_grid_width(v):
	._set_grid_width(v)


func _set_cell_size(v):
	._set_cell_size(v)


func _set_grid_height(v):
	height = v
	regenerate_view()


func _set_border_width(v):
	border_width = v
	regenerate_view()


func _set_inventory(v):
	width = v.get_width()
	height = v.get_height()
	._set_inventory(v)


func _ready2():
	_set_inventory(GridInventory.new(width, height))


func regenerate_view():
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


func global_position_to_cell(pos : Vector2, item : ItemStack) -> Vector2:
	return (Vector2(
		(pos.x - rect_global_position.x - border_width) / cell_size.x,
		(pos.y - rect_global_position.y - border_width) / cell_size.y
	) - item.item_type.get_size_in_inventory() * 0.5).round()


func _position_item(node : Control, item_stack : ItemStack):
	node.rect_position = cell_size * item_stack.position_in_inventory + Vector2(border_width, border_width)
