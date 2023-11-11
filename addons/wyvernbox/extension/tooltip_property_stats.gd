extends InventoryTooltipProperty

static var all_bonuses_dict := {}

const item_bonus_locale_string := "item_bonus_%s"
const item_bonus_paths := "res://example/wyvernbox/equip_bonuses/"
const wyvernshield_suffixes := [43, 37, 36, 42, 38, 47, 94, 95]  # "+%$*&/^_"
const wyvernshield_suffix_labels := ["{0}", "{0}%", "x{0}", "x{0}", "{0}", "{0}", "{0}", "{0}"]
const wyvernshield_suffix_show_plus := [true, true, false, false, true, true, false, false]

## Returns a formatted display of a stat with a value. [br]
## If [code]use_rich[/code], you can specify colors for bonus (+), malus (-) and neutral (=0)
static func get_stat_label(stat_with_suffix : String, values, use_rich : bool = false, hex_bonus : String = "858ffd", hex_malus : String = "ff6060", hex_neutral : String = "6a6a6a") -> String:
	if !values is Array: values = [values]
	var first := true
	var stat_suffix_idx : int = wyvernshield_suffixes.find(stat_with_suffix.unicode_at(stat_with_suffix.length() - 1))
	var line := ""
	for i in values.size():
		var value = values[i]
		if use_rich:
			line += ("%s[color=#%s]%s%s" % [
				("" if first else "/"),
				(hex_bonus if value > 0.0 else (hex_neutral if value == -0.0 else hex_malus)),
				("+" if value >= 0.0 && (stat_suffix_idx == -1 || wyvernshield_suffix_show_plus[stat_suffix_idx]) else ""),
				value
			])
		first = false

	if stat_suffix_idx != -1:
		line = wyvernshield_suffix_labels[stat_suffix_idx].format([line])

	var bonus_res : EquipBonus = null
	if !all_bonuses_dict.has(stat_with_suffix):
		bonus_res = load(item_bonus_paths.path_join(stat_with_suffix.left(stat_with_suffix.length() - 1) if stat_suffix_idx != -1 else stat_with_suffix) + ".tres")
		all_bonuses_dict[stat_with_suffix] = bonus_res

	else:
		bonus_res = all_bonuses_dict[stat_with_suffix]

	if bonus_res == null:
		line += (
			" "
			+ TranslationServer.translate(item_bonus_locale_string % stat_with_suffix)
			+ ("[/color]" if use_rich else "")
		)

	else:
		line += (
			" "
			+ TranslationServer.translate(bonus_res.name)
			+ ("[/color]" if use_rich else "")
		)

	return line


func _display(item_stack):
	if item_stack.extra_properties.has(&"stats"):
		add_bbcode("\n")
		_show_equip_stats(item_stack)


func _get_stats_bbcode(displayed_stats : Dictionary, hex_bonus : String, hex_neutral : String, hex_malus : String) -> String:
	var value := 0.0
	var text : Array[String] = []
	for k in displayed_stats:
		text.append(get_stat_label(k, displayed_stats[k], true, hex_bonus, hex_malus, hex_neutral))

	return "\n".join(text)


func _show_equip_stats(item_stack : ItemStack):
	var stats = item_stack.extra_properties[&"stats"]
	var hex_bonus = tooltip.color_bonus.to_html(false)
	var hex_malus = tooltip.color_malus.to_html(false)
	var hex_neutral = tooltip.color_neutral.to_html(false)

	var displayed_stats := {}
	for k in stats:
		displayed_stats[k] = stats[k]
	
	if !Input.is_action_pressed(tooltip.compare_input):
		for k in displayed_stats:
			displayed_stats[k] = [displayed_stats[k]]

		add_bbcode(_get_stats_bbcode(displayed_stats, hex_bonus, hex_neutral, hex_malus))
		return

	var compared := _get_compared_item_stats(item_stack)
	if compared.size() == 0:
		for k in displayed_stats:
			displayed_stats[k] = [displayed_stats[k]]

		add_bbcode(_get_stats_bbcode(displayed_stats, hex_bonus, hex_neutral, hex_malus))
		return
		
	for k in displayed_stats:
		var arr := []
		arr.resize(compared.size())
		arr.fill(displayed_stats[k])
		displayed_stats[k] = arr

	for i in compared.size():
		for k in compared[i]:
			if !displayed_stats.has(k):
				var arr := []
				arr.resize(compared.size())
				arr.fill(0.0)
				displayed_stats[k] = arr

			displayed_stats[k][i] -= compared[i].get(k, 0.0)

	add_bbcode(_get_stats_bbcode(displayed_stats, hex_bonus, hex_neutral, hex_malus))


func _get_compared_item_stats(to_item : ItemStack) -> Array:
	if tooltip.compare_to_inventory.is_empty():
		return []

	var inv = tooltip.get_node(tooltip.compare_to_inventory).inventory._cells
	var result := []
	var to_flags := to_item.item_type.slot_flags
	for x in inv:
		if x == null: continue
		if x.item_type.slot_flags & to_flags & ItemType.EQUIPMENT_FLAGS != 0:
			result.append(x.extra_properties["stats"])

	return result
