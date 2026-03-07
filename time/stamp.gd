@onready var stamp: Sprite2D = $StampAnim

func _play_stamp():
	stamp.visible = true
	stamp.scale = Vector2(1.8, 1.8)
	stamp.modulate = Color(1, 1, 1, 1)

	var tween = create_tween()
	# Slam in
	tween.tween_property(stamp, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Hold for a moment
	tween.tween_interval(0.4)
	# Fade out
	tween.tween_property(stamp, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): stamp.visible = false)
