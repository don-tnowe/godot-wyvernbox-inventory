extends Control


export var shown_res : Resource


func show_bonus(bonus_res : Resource, label : String, label_color : Color = Color.white, background : Texture = null):
  shown_res = bonus_res
  show()
  $"Back".texture = bonus_res.icon_back if background == null else background
  $"Icon".texture = bonus_res.icon
  $"Value".text = label
  $"Value".self_modulate = label_color


func _on_Bonus_mouse_exited():
  get_tree().get_nodes_in_group("tooltip")[0].hide()


func _on_Bonus_mouse_entered():
  var tt = get_tree().get_nodes_in_group("tooltip")[0]
  tt.display_bonus(self, shown_res)
