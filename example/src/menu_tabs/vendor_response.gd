extends Label


func _ready():
	call_deferred("say", "shopkeeper_hello", Color.GREEN)


func say(say_text, color = Color(1.0, 0.9, 0.1, 1.0)):
	text = say_text
	modulate = color

	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1)


func _on_ShopManager_item_received(_stack):
	say("shopkeeper_sold", Color.GREEN)


func _on_ShopManager_item_given(_stack):
	say("shopkeeper_purchase", Color.DARK_TURQUOISE)


func _on_ShopManager_item_cant_afford(_stack):
	say("shopkeeper_cant_afford", Color.RED)
