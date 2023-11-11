extends VBoxContainer

@export var base_stats : Dictionary = {
  "health+" : 20.0,
  "magic+" : 0.0,
  "weapon_speed+" : 1.0,
  "crit_power+" : 150.0,
}
@export var equip_inventory_view := NodePath("../Equip")

@export_group("Fluff")
@export var no_weapon_text := "Left Hook Right Hook Jab"
@export var crit_stat_text := "Chance for x%s Damage:"

var stats := {}
var stats_per_item := {}


func _ready():
	update_view()


func _on_Equip_item_stack_removed(item_stack):
	stats_per_item[item_stack.position_in_inventory] = []
	update_view()


func _on_Equip_item_stack_added(item_stack):
	var item_stats = item_stack.extra_properties[&"stats"]
	stats_per_item[item_stack.position_in_inventory] = item_stats
	update_view()
	

func update_view():
	stats.clear()
	for k in base_stats:
		stats[k] = base_stats[k]

	for k in stats_per_item:
		for l in stats_per_item[k]:
			stats[l] = stats.get(l, 0.0) + stats_per_item[k][l]

	_update_stat_view.call_deferred()


func _update_stat_view():
	_update_hpmp()
	_update_weapon_stats()
	_update_nullable($"OffDef/Off/HBoxContainer/W", "weapon_damage+")
	_update_nullable($"OffDef/Off/HBoxContainer/S", "spell_damage+")
	_update_nullable($"OffDef/Def/HBoxContainer/Def", "defense+")
	_update_nullable($"OffDef/Def/HBoxContainer/Dodge", "dodgerate+")

	var already_shown_stats = {
		&"weapon_damage+" : true,
		&"weapon_speed+" : true,
		&"spell_damage+" : true,
		&"defense+" : true,
		&"dodgerate+" : true,
		&"health+" : true,
		&"magic+" : true,
		&"health_regen+" : true,
		&"magic_regen+" : true,
		&"crit_chance+" : true,
		&"crit_power+" : true,
	}
	var other_list : RichTextLabel = $"OtherStats"
	other_list.clear()
	var stats_sorted = stats.keys()
	stats_sorted.sort()
	var equip_bonus_tooltip : Script = load("res://addons/wyvernbox/extension/tooltip_property_stats.gd")
	for k in stats_sorted:
		if k in already_shown_stats:
			continue
		
		other_list.append_text(equip_bonus_tooltip.get_stat_label(k, floor(stats.get(k, 0.0) * 1000) * 0.001, true, "858ffd", "858ffd", "858ffd") + "\n")

func _update_hpmp():
	var health_str := str(stats.get(&"health+", 0.0))
	$"Hpmp/Hp/Num".text = (
		health_str + "/" + health_str  # TODO: replace with actual health
		if stats.get(&"health_regen+", 0.0) == 0 else
		"%s/%s (+%s/s)" % [
		health_str,
		health_str,
		stats.get(&"health_regen+", 0.0),
	])
	var magic_str := str(stats.get(&"magic+", 0.0))
	$"Hpmp/Mp/Num".text = (
		magic_str + "/" + magic_str  # TODO: replace with actual magic energy
		if stats.get(&"magic_regen+", 0.0) == 0 else
		"%s/%s (+%s/s)" % [
		magic_str,
		magic_str,
		stats.get(&"magic_regen+", 0.0),
	])


func _update_weapon_stats():
	var weapon = get_node(equip_inventory_view).inventory.get_item_at_position(0, 0)
	$"WeaponName".text = weapon.get_name() if weapon != null else no_weapon_text
	$"Weapon/B/Dmg/Value".text = str(stats.get("weapon_damage", 0.0) * stats.get("weapon_speed", 1.0))
	$"Weapon/B/Crit/Value".text = str(stats.get("crit_chance", 0.0)) + "%"

	var crit_label := tr(crit_stat_text)
	if !("%s" in crit_label || "%d" in crit_label || "%f" in crit_label):
    # Epic localization fail (Github #17)
		crit_label += " %s"
	
	$"Weapon/B/Crit/Label".text = crit_label % (stats.get("crit_power", 0.0) * 0.01)


func _update_nullable(node, stat, prefix : String = "", add_to_value : float = 0.0, hide_if_zero : bool = false):
	var value = stats.get(stat, 0.0)
	if hide_if_zero && value == 0:
		node.hide()
		return
	
	node.show()
	_update_icon(node, str(value + add_to_value) + prefix, (
			Color.WHITE
			if value > 0.01 else
			Color(0.25, 0.25, 0.25)
			if value <= 0.01 else
			Color(1, 0.25, 0.25)
		), (
			Color.WHITE
			if value != 0 else
			Color(0.0, 0.0, 0.0, 0.5)
		), (
			Color.WHITE
			if value != 0 else
			Color.TRANSPARENT
		)
	)


func _update_icon(node, label, label_color = Color.WHITE, icon_color = Color.WHITE, back_color = Color.WHITE):
	node.get_node("Value").text = label
	node.get_node("Value").self_modulate = label_color
	node.get_node("Icon").self_modulate = icon_color
	node.get_node("Back").self_modulate = back_color
