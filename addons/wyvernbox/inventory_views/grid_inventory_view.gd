tool
class_name GridInventoryView, "res://addons/wyvernbox/icons/grid_inventory.png"
extends InventoryView

# How many cells this inventory spans horizontally.
export var width := 12 setget _set_grid_width

# How many cells this inventory spans vertically.
export var height := 8 setget _set_grid_height

# The width of the border around the inventory's cells.
export var border_width := 1.0 setget _set_border_width

# The node 
export var background_texture_node : NodePath

#
export var tex_from_viewport : NodePath


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
	get_node(background_texture_node).hide()
	get_node(background_texture_node).show()
	._set_inventory(v)


func _ready2():
	_set_inventory(GridInventory.new(width, height))


func _regenerate_view():
	if !is_inside_tree(): yield(self, "ready")
	if item_scene == null: return
	
	var tex_viewport = get_node(tex_from_viewport)
	tex_viewport.get_child(0).rect_size = cell_size
	tex_viewport.size = cell_size
	
	var new_size := Vector2(border_width * 2, border_width * 2) + cell_size * Vector2(width, height)
	rect_min_size = new_size
	rect_size = new_size
	get_node(background_texture_node).rect_min_size = new_size - 2 * Vector2(border_width, border_width)

	var vp_tex = tex_viewport.get_texture()
	if Engine.editor_hint:
		# Prevent errors in editor: get_texture() returns tex with no path
		if get_node(background_texture_node).texture is ViewportTexture:
			return

		vp_tex.viewport_path = tex_viewport.owner.get_path_to(tex_viewport)

	get_node(background_texture_node).texture = vp_tex

# Returns the position of the cell clicked from `pos`.
# `item`'s size is used for position correction.
func global_position_to_cell(pos : Vector2, item : ItemStack) -> Vector2:
	var topleft = get_node(background_texture_node).rect_global_position
	return (Vector2(
		(pos.x - topleft.x - border_width) / cell_size.x,
		(pos.y - topleft.y - border_width) / cell_size.y
	) - item.item_type.get_size_in_inventory() * 0.5).round()


func _position_item(node : Control, item_stack : ItemStack):
	node.rect_global_position = get_node(background_texture_node).rect_global_position + cell_size * item_stack.position_in_inventory
