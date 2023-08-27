extends Control

@export var filter_bonus_tutorial_label := "%s to highlight items with this."

# The [EquipBonus] displayed here. Defines icon and tooltip contents.
@export var shown_res : EquipBonus


# Sets the displayed [EquipBonus] with [code]label[/code] of [code]label_color[/code].
# Optionally, pass a background texture. If not set, uses the bonus's default background.
func show_bonus(bonus_res : EquipBonus, label : String, label_color : Color = Color.WHITE, background : Texture2D = null):
	shown_res = bonus_res
	show()
	$"Back".texture = bonus_res.texture_back if background == null else background
	$"Icon".texture = bonus_res.texture
	$"Value".text = label
	$"Value".self_modulate = label_color

## Displays the name and description of an [EquipBonus].
## [code]node[/code] is the [Control] this tooltip must be placed next to.
func tooltip_display_bonus(bonus_res : EquipBonus):
	var tt := InventoryTooltip.get_instance()
	if !is_instance_valid(tt):
		return

	var desc = tr(bonus_res.description)
	if desc == bonus_res.description:
		desc = ""

	tt.display_custom(
		self,
		tr(bonus_res.name),
		"[center]\n%s\n\n%s" % [desc, filter_bonus_tutorial_label % tt.get_action_bbcode(tt.filter_input)],
		[ItemPatternEquipStat.new([], [], [bonus_res.id])],
	)


func _on_Bonus_mouse_exited():
	var tooltip := InventoryTooltip.get_instance()
	if is_instance_valid(tooltip):
		tooltip.hide()


func _on_Bonus_mouse_entered():
	var tooltip := InventoryTooltip.get_instance()
	if is_instance_valid(tooltip):
		tooltip_display_bonus(shown_res)
