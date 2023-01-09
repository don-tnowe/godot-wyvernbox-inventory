class_name ItemPatternHighlightStack
extends ItemPattern

var item : ItemStack


func _init(items := [], efficiency := [], match_stack = null).(items, efficiency):
	item = match_stack


func matches(item_stack : ItemStack) -> bool:
	return item_stack == item || .matches(item_stack)
