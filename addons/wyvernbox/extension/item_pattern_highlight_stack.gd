class_name ItemPatternHighlightStack
extends ItemPattern

## Apart from [code]items[/code], also match this stack.
var item : ItemStack


func _init(items := [], efficiency := [], match_stack = null):
	super(items, efficiency)
	item = match_stack

## Returns [code]true[/code] if the stack is the [member item] to highlight, or matches the pattern normally.
func matches(item_stack : ItemStack) -> bool:
	return item_stack == item || super.matches(item_stack)
