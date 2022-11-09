class_name EquipBonus
extends Resource

export var id := "health"
export var icon : Texture
export var icon_back : Texture
export var max_level := 10
export var bonus_init := 10.0
export var bonus_linear := 5.0
export var bonus_quad := 0.2

export var is_percentage := false
export var integer_only := true
export var affix_position := -1


func get_value(level : int = 1) -> float:
	if !integer_only:
		return bonus_init + bonus_linear * level + bonus_quad * level * level

	else:
		return floor(bonus_init + bonus_linear * level + bonus_quad * level * level)


func apply_to(stats_dict : Dictionary, level : int, multiplier : float = 1.0):
	stats_dict[id] = stats_dict.get(id, 0.0) + get_value(level) * multiplier


func append_affix(affixes_array : Array):
	if affix_position < 0:
		affixes_array.insert(0, id)

	else:
		affixes_array.append(id)
