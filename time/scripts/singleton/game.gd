extends Node

enum HandState {
	OPEN,
	GRAB,
	WRITE,
}

signal hand_state_changed(old_state: HandState, new_state: HandState)
signal distraction_force_open_changed(is_forced_open: bool)

var hand_state: HandState = HandState.WRITE
var _forced_open_count: int = 0
var _state_before_forced_open: HandState = HandState.WRITE


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

func begin_distraction_force_open() -> void:
	if _forced_open_count == 0:
		_state_before_forced_open = hand_state
		set_hand_open()
		distraction_force_open_changed.emit(true)
	_forced_open_count += 1

func end_distraction_force_open() -> void:
	if _forced_open_count <= 0:
		return

	_forced_open_count -= 1
	if _forced_open_count > 0:
		return

	if hand_state == HandState.OPEN or hand_state == HandState.GRAB:
		set_hand_state(_state_before_forced_open)
	distraction_force_open_changed.emit(false)

func is_forced_open_active() -> bool:
	return _forced_open_count > 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
