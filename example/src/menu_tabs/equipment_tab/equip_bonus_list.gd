extends VBoxContainer

export var equip_inventory_view := NodePath("../Equip")

var stats := {}
var stats_per_item := {}


func _ready():
	update_view()


func _on_Equip_item_stack_removed(item_stack):
	stats_per_item[item_stack.position_in_inventory] = []
	update_view()


func _on_Equip_item_stack_added(item_stack):
	var item_stats = item_stack.extra_properties["stats"]
	stats_per_item[item_stack.position_in_inventory] = item_stats
	update_view()
	

func update_view():
	stats.clear()
	for k in stats_per_item:
		for l in stats_per_item[k]:
			stats[l] = stats.get(l, 0.0) + stats_per_item[k][l]

	call_deferred("_update_stat_view")


func _update_stat_view():
	_update_hpmp()
	_update_weapon_stats()
	_update_nullable($"OffDef/Off/HBoxContainer/W", "weapon_damage")
	_update_nullable($"OffDef/Off/HBoxContainer/S", "spell_damage")
	_update_nullable($"OffDef/Def/HBoxContainer/Def", "defense")
	_update_nullable($"OffDef/Def/HBoxContainer/Dodge", "dodgerate")

	var already_shown_stats = {
		"weapon_damage" : true,
		"weapon_speed" : true,
		"spell_damage" : true,
		"defense" : true,
		"dodgerate" : true,
		"health" : true,
		"magic" : true,
		"health_regen" : true,
		"magic_regen" : true,
		"crit_chance" : true,
		"crit_power" : true,
	}
	var other_list = $"OtherStats"
	other_list.bbcode_text = ""
	var stats_sorted = stats.keys()
	stats_sorted.sort()
	for k in stats_sorted:
		if k in already_shown_stats:
			continue
		
		other_list.append_bbcode(
			"[color=#858ffd]"
			+ ("%.1f" % (stats.get(k, 0.0)))
			+ "[/color] "
			+ tr("item_bonus_" + k)
			+ "\n"
		)


func _update_hpmp():
	var health_str := str(stats.get("health", 0.0))
	$"Hpmp/Hp/Num".text = (
		health_str + "/" + health_str  # TODO: replace with actual health
		if stats.get("health_regen", 0.0) == 0 else
		"%s/%s (+%s/s)" % [
		health_str,
		health_str,
		stats.get("health_regen", 0.0),
	])
	var magic_str := str(stats.get("magic", 0.0))
	$"Hpmp/Mp/Num".text = (
		magic_str + "/" + magic_str  # TODO: replace with actual magic energy
		if stats.get("magic_regen", 0.0) == 0 else
		"%s/%s (+%s/s)" % [
		magic_str,
		magic_str,
		stats.get("magic_regen", 0.0),
	])


func _update_weapon_stats():
	var weapon = get_node(equip_inventory_view).inventory.get_item_at_position(0, 0)
	$"WeaponName".text = weapon.get_name() if weapon != null else "no_weapon"
	$"Weapon/B/Dmg/Value".text = str(stats.get("weapon_damage", 0.0) * stats.get("weapon_speed", 1.0))
	$"Weapon/B/Crit/Label".text = tr("stats_crit") % (stats.get("crit_power", 0.0) * 0.01)
	$"Weapon/B/Crit/Value".text = str(stats.get("crit_chance", 0.0)) + "%"


func _update_nullable(node, stat, prefix : String = "", add_to_value : float = 0.0, hide_if_zero : bool = false):
	var value = stats.get(stat, 0.0)
	if hide_if_zero && value == 0:
		node.hide()
		return
	
	node.show()
	_update_icon(node, str(value + add_to_value) + prefix, (
			Color.white
			if value > 0.01 else
			Color(0.25, 0.25, 0.25)
			if value <= 0.01 else
			Color(1, 0.25, 0.25)
		), (
			Color.white
			if value != 0 else
			Color(0.0, 0.0, 0.0, 0.5)
		), (
			Color.white
			if value != 0 else
			Color.transparent
		)
	)


func _update_icon(node, label, label_color = Color.white, icon_color = Color.white, back_color = Color.white):
	node.get_node("Value").text = label
	node.get_node("Value").self_modulate = label_color
	node.get_node("Icon").self_modulate = icon_color
	node.get_node("Back").self_modulate = back_color
