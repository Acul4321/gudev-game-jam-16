extends Node2D

@export var distraction_scene: PackedScene = preload("res://distractions/distraction.tscn")
@export var distraction_resources: Array[DistractionResource] = [
	preload("res://distractions/coffee_distraction.tres"),
	preload("res://distractions/cat_distraction.tres"),
	preload("res://distractions/phone_distraction.tres"),
]
@export var min_spawn_interval: float = 4.0
@export var max_spawn_interval: float = 8.0
@export var max_active_distractions: int = 2
@export var spawn_margin: float = 80.0
@export var min_spawn_rotation_degrees: float = -180.0
@export var max_spawn_rotation_degrees: float = 180.0
@export var countdown_seconds: int = 60
@export var end_scene_path: String = "res://menu/end_screen.tscn"

@onready var distractions_root: Node2D = $Distractions
@onready var digit1_label: Label = %digit1
@onready var digit2_label: Label = %digit2

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _countdown_timer: Timer
var _remaining_seconds: int = 0
var _has_ended: bool = false


func _ready() -> void:
	Music.play(&"Time Loop In Game", true, 0.0)
	Game.reset_score()
	_rng.randomize()
	_start_countdown()
	_schedule_next_spawn()


func _start_countdown() -> void:
	_remaining_seconds = maxi(countdown_seconds, 0)
	_update_timer_labels(_remaining_seconds)

	_countdown_timer = Timer.new()
	_countdown_timer.one_shot = false
	_countdown_timer.wait_time = 1.0
	_countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(_countdown_timer)
	_countdown_timer.start()


func _on_countdown_tick() -> void:
	if _has_ended:
		return

	_remaining_seconds -= 1
	_update_timer_labels(_remaining_seconds)

	if _remaining_seconds <= 0:
		_end_game()


func _update_timer_labels(seconds_left: int) -> void:
	var clamped_seconds: int = maxi(seconds_left, 0)
	var tens: int = int(clamped_seconds / 10)
	var ones: int = clamped_seconds % 10
	digit1_label.text = str(tens)
	digit2_label.text = str(ones)


func _end_game() -> void:
	if _has_ended:
		return
	_has_ended = true

	if is_instance_valid(_countdown_timer):
		_countdown_timer.stop()

	get_tree().change_scene_to_file(end_scene_path)


func _schedule_next_spawn() -> void:
	var delay: float = _rng.randf_range(min_spawn_interval, max_spawn_interval)
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(_try_spawn_distraction)


func _try_spawn_distraction() -> void:
	if not is_instance_valid(distraction_scene):
		return

	if get_tree().get_nodes_in_group("distractions").size() >= max_active_distractions:
		_schedule_next_spawn()
		return

	var distraction := distraction_scene.instantiate() as Node2D
	var picked_resource: DistractionResource = _pick_random_resource()
	if picked_resource:
		distraction.set("distractionResource", picked_resource)
	distractions_root.add_child(distraction)
	distraction.global_position = _pick_spawn_position()
	distraction.rotation_degrees = _rng.randf_range(min_spawn_rotation_degrees, max_spawn_rotation_degrees)
	_schedule_next_spawn()


func _pick_spawn_position() -> Vector2:
	var rect := get_viewport().get_visible_rect().grow(-spawn_margin)
	return Vector2(
		_rng.randf_range(rect.position.x, rect.end.x),
		_rng.randf_range(rect.position.y, rect.end.y)
	)


func _pick_random_resource() -> DistractionResource:
	if distraction_resources.is_empty():
		return null

	var total_weight: float = 0.0
	for resource in distraction_resources:
		if resource:
			total_weight += maxf(resource.spawnChancePercent, 0.0)

	if total_weight <= 0.0:
		var index: int = _rng.randi_range(0, distraction_resources.size() - 1)
		return distraction_resources[index]

	var roll: float = _rng.randf_range(0.0, total_weight)
	var running_weight: float = 0.0
	for resource in distraction_resources:
		if not resource:
			continue
		running_weight += maxf(resource.spawnChancePercent, 0.0)
		if roll <= running_weight:
			return resource

	return distraction_resources[distraction_resources.size() - 1]
