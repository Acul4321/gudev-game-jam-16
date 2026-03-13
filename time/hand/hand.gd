extends Node2D

@onready var write_visual: Sprite2D = $writeVisual
@onready var open_visual: Sprite2D = $openVisual
@onready var grab_visual: Sprite2D = $grabVisual

var _holding_from_open: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Game.hand_state_changed.is_connected(_on_hand_state_changed):
		Game.hand_state_changed.connect(_on_hand_state_changed)
	_update_visuals(Game.get_hand_state())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if Game.is_hand_open():
				_holding_from_open = true
				Game.set_hand_grab()
		else:
			if _holding_from_open:
				_holding_from_open = false
				if Game.is_hand_grabbing():
					Game.set_hand_open()


func _on_hand_state_changed(_old_state: int, new_state: int) -> void:
	_update_visuals(new_state)


func _update_visuals(state: int) -> void:
	write_visual.visible = state == Game.HandState.WRITE
	open_visual.visible = state == Game.HandState.OPEN
	grab_visual.visible = state == Game.HandState.GRAB
