extends Label


func _ready():
	say.call_deferred("Welcome! Check out my wares!", Color.GREEN)


func say(say_text, color = Color(1.0, 0.9, 0.1, 1.0)):
	text = say_text
	modulate = color

	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1)


func _on_ShopManager_item_received(_stack):
	say("Mmm... a fine addition to my collection!", Color.GREEN)


func _on_ShopManager_item_given(_stack):
	say("Hohoho! Hope you enjoy it!", Color.DARK_TURQUOISE)


func _on_ShopManager_item_cant_afford(_stack):
	say("Hah! Out of your league. Come back when you're... a little richer!", Color.RED)
