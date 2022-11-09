class_name EquipmentMaterials
extends Control

export var library : Resource
export var row_height := 10.0
export var bottom_padding := 2.0
export var width := 192.0

var _mats
var _mats_array
var _widths


func display(mats : Dictionary):
	_mats = mats
	_mats_array = PoolStringArray([])
	if mats.size() == 0:
		update()
		_widths = null
		rect_min_size = Vector2.ZERO
		return
	
	var keys = mats.keys()
	keys.sort()
	_widths = [0]
	var cur_width := 0
	var cur_row := 0

	for x in keys:
		for i in mats[x]:
			cur_width = library.materials_dict[x].texture.get_width()
			if _widths[cur_row] + cur_width > width:
				cur_row += 1
				_widths.append(0)
				
			_mats_array.append(x)
			_widths[cur_row] += cur_width
	
	rect_min_size.x = _widths.max()
	rect_min_size.y = _widths.size() * row_height + bottom_padding
	update()


func _draw():
	if _widths == null: return

	var cur_x = -_widths[0] * 0.5
	var cur_width = 0
	var cur_row = 0
	for x in _mats_array:
		cur_width = library.materials_dict[x].texture.get_width()
		if cur_x + cur_width > _widths[cur_row] * 0.5:
			cur_row += 1
			cur_x = -_widths[cur_row] * 0.5
		
		draw_texture(
			library.materials_dict[x].texture,
			Vector2(
				cur_x + rect_size.x * 0.5,
				row_height * cur_row
			)
		)
		cur_x += cur_width
	
	update()
