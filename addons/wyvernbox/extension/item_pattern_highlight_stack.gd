class_name ItemPatternHighlightStack
extends ItemPattern

# Apart from `items`, also match this stack.
var item : ItemStack


func _init(items := [], efficiency := [], match_stack = null).(items, efficiency):
	item = match_stack

# Returns `true` if the stack is the `item` to highlight, or matches the pattern normally.
func matches(item_stack : ItemStack) -> bool:
	return item_stack == item || .matches(item_stack)
