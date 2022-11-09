extends Button


func _pressed():
  for x in get_tree().get_nodes_in_group("inventory_view"):
    x.clear_filters()
