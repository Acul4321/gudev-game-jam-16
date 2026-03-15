extends Node2D

func _ready() -> void:
	%enterButton.pressed.connect(_on_enter_button_pressed)
	Music.play_song.emit(&"Time Loop Main Menu", true, false, 0.0)

func _on_enter_button_pressed() -> void:
	if %manuscriptEdit.text.strip_edges() == "":
		Game.manuscript_title = "Forgottenly named Manuscript"
	else:
		Game.manuscript_title = %manuscriptEdit.text.strip_edges()
	get_tree().change_scene_to_file("res://main/main.tscn")
