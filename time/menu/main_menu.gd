extends Node2D

func _ready() -> void:
	%enterButton.pressed.connect(_on_enter_button_pressed)
	%manuscriptEdit.text_submitted.connect(_on_manuscript_submitted)
	Music.play(&"Time Loop Main Menu", true)

func _on_manuscript_submitted(_new_text: String) -> void:
	_on_enter_button_pressed()

func _on_enter_button_pressed() -> void:
	var title: String = %manuscriptEdit.text.strip_edges()
	if title == "":
		Game.manuscript_title = "Forgottenly named Manuscript"
	else:
		Game.manuscript_title = title

	get_tree().change_scene_to_file("res://main/main.tscn")
