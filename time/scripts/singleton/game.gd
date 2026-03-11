extends Node

enum HandState {
	OPEN,
	GRAB,
	WRITE,
}

signal hand_state_changed(old_state: HandState, new_state: HandState)

var hand_state: HandState = HandState.OPEN


func set_hand_state(new_state: HandState) -> void:
	if new_state == hand_state:
		return

	var previous_state: HandState = hand_state
	hand_state = new_state
	hand_state_changed.emit(previous_state, hand_state)


func get_hand_state() -> HandState:
	return hand_state


func is_hand_open() -> bool:
	return hand_state == HandState.OPEN


func is_hand_grabbing() -> bool:
	return hand_state == HandState.GRAB


func can_write() -> bool:
	return hand_state == HandState.WRITE


func set_hand_open() -> void:
	set_hand_state(HandState.OPEN)


func set_hand_grab() -> void:
	set_hand_state(HandState.GRAB)


func set_hand_write() -> void:
	set_hand_state(HandState.WRITE)


func cycle_hand_state() -> void:
	set_hand_state((hand_state + 1) % HandState.size())


func hand_state_to_string(state: HandState = hand_state) -> String:
	match state:
		HandState.OPEN:
			return "OPEN"
		HandState.GRAB:
			return "GRAB"
		HandState.WRITE:
			return "WRITE"
		_:
			return "UNKNOWN"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
