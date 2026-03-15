extends Node2D

const GRADE_A_PLUS: Texture2D = preload("res://menu/A+.png")
const GRADE_A: Texture2D = preload("res://menu/A.png")
const GRADE_B: Texture2D = preload("res://menu/B.png")
const GRADE_C: Texture2D = preload("res://menu/C.png")
const GRADE_F: Texture2D = preload("res://menu/F.png")

const THRESHOLD_A_PLUS: int = 40
const THRESHOLD_A: int = 30
const THRESHOLD_B: int = 20
const THRESHOLD_C: int = 10



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%returnButton.pressed.connect(_on_return_button_pressed)
	Music.play_song.emit(&"Time Loop End Menu", true, false, 0.0)
	%manuscriptLabel.text = Game.manuscript_title
	%totalScoreLabel.text = "Total Score: %d" % ((Game.score + 32) * 42)
	%pagesFilledLabel.text = "Pages Filled: %d" % Game.pages_filled
	%distractionsThrownLabel.text = "Distractions Thrown: %d" % Game.distractions_thrown
	%gradeSprite.texture = _get_grade_texture(Game.score)


func _get_grade_texture(total_score: int) -> Texture2D:
	if total_score >= THRESHOLD_A_PLUS:
		return GRADE_A_PLUS
	if total_score >= THRESHOLD_A:
		return GRADE_A
	if total_score >= THRESHOLD_B:
		return GRADE_B
	if total_score >= THRESHOLD_C:
		return GRADE_C
	return GRADE_F


func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/main_menu.tscn")
