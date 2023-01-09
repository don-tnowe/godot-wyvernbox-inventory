class_name ItemPatternName
extends ItemPattern

export var name_to_search := ""


func _init(name_to_search, items := [], efficiency := []).(items, efficiency):
	self.name_to_search = name_to_search


func matches(item_stack : ItemStack) -> bool:
	if !.matches(item_stack):
		return false

	return item_stack.get_name().findn(name_to_search) != -1
