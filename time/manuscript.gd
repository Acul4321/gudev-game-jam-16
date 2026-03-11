extends Node2D

const GRID_W: int = 10
const GRID_H: int = 10
const FILL_THRESHOLD: float = 0.50

@export var pile_position: Vector2 = Vector2(-300, 200)
const PILE_SCALE: float = 0.4

@onready var paper_bg: TextureRect = $PaperBG
@onready var scribble_line: Line2D = $ScribbleLine

var paper_size: Vector2
var cell_size: Vector2
var grid: Array = []
var last_fill_pos: Vector2 = Vector2(-1, -1)


func _process(_delta: float):
	print("Fill: %.1f%%" % (get_fill_pct() * 100.0))
	if get_fill_pct() >= FILL_THRESHOLD:
		_complete_page()
			
func _ready():
	paper_size = paper_bg.size
	cell_size = Vector2(paper_size.x / GRID_W, paper_size.y / GRID_H)
	_reset_grid()

func _reset_grid():
	grid = []
	for y in range(GRID_H):
		var row: Array = []
		for x in range(GRID_W):
			row.append(false)
		grid.append(row)

var is_drawing: bool = false

var current_line: Line2D = null

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var local_pos = to_local(event.global_position)
			if _is_on_paper(local_pos):
				is_drawing = true
				last_fill_pos = Vector2(-1, -1)
				# New Line2D for each stroke
				current_line = Line2D.new()
				current_line.width = 10.0
				current_line.default_color = Color(0.1, 0.1, 0.2)
				add_child(current_line)
				current_line.add_point(local_pos + _wobble())
		else:
			is_drawing = false
			last_fill_pos = Vector2(-1, -1)

	if event is InputEventMouseMotion and is_drawing:
		var local_pos = to_local(event.global_position)
		if _is_on_paper(local_pos) and current_line:
			current_line.add_point(local_pos + _wobble())
			_fill_cells_along(local_pos)

func _is_on_paper(local_pos: Vector2) -> bool:
	var paper_rect = Rect2(Vector2.ZERO, paper_size)
	return paper_rect.has_point(local_pos)

func _wobble() -> Vector2:
	return Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))

func _fill_cell_at(local_pos: Vector2):
	var gx: int = int(local_pos.x / cell_size.x)
	var gy: int = int(local_pos.y / cell_size.y)
	gx = clampi(gx, 0, GRID_W - 1)
	gy = clampi(gy, 0, GRID_H - 1)
	grid[gy][gx] = true
	
func get_fill_pct() -> float:
	var filled: int = 0
	for row in grid:
		for cell in row:
			if cell:
				filled += 1
	return float(filled) / float(GRID_W * GRID_H)
	
func _fill_cells_along(local_pos: Vector2):
	# Fill the cell at the current position
	_fill_single_cell(local_pos)

	# Fill cells between last position and current (interpolate)
	if last_fill_pos != Vector2(-1, -1):
		var dist = local_pos.distance_to(last_fill_pos)
		var steps = int(dist / min(cell_size.x, cell_size.y))  # one fill per cell-width
		for i in range(1, steps):
			var t = float(i) / float(steps)
			var interp = last_fill_pos.lerp(local_pos, t)
			_fill_single_cell(interp)

	last_fill_pos = local_pos

func _fill_single_cell(local_pos: Vector2):
	var gx: int = int(local_pos.x / cell_size.x)
	var gy: int = int(local_pos.y / cell_size.y)
	gx = clampi(gx, 0, GRID_W - 1)
	gy = clampi(gy, 0, GRID_H - 1)
	grid[gy][gx] = true
	
signal page_completed(page_number: int)

var pages: int = 0

func _complete_page():
	pages += 1
	is_drawing = false
	last_fill_pos = Vector2(-1, -1)
	
	# --- Snapshot the current page ---
	var snapshot = Node2D.new()
	
	# Use Sprite2D, NOT TextureRect — it actually scales with the parent
	var paper_copy = Sprite2D.new()
	paper_copy.texture = paper_bg.texture
	paper_copy.centered = false
	# Match the TextureRect's display size, not the image's native size
	var tex_size = paper_bg.texture.get_size()
	paper_copy.scale = paper_size / tex_size
	snapshot.add_child(paper_copy)
	
	# Move all Line2D strokes into the snapshot
	for child in get_children():
		if child is Line2D:
			remove_child(child)
			snapshot.add_child(child)
	
	current_line = null
	
	# Add snapshot as sibling (so it's outside the manuscript)
	get_parent().add_child(snapshot)
	snapshot.global_position = global_position
	
	# --- Stamp, then fly to pile ---
	stamp.visible = true
	stamp.scale = Vector2(1.8, 1.8)
	stamp.modulate = Color(1, 1, 1, 1)
	
	var tween = create_tween()
	# Stamp slam
	tween.tween_property(stamp, "scale", Vector2(1.0, 1.0), 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(0.3)
	tween.tween_property(stamp, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_callback(func(): stamp.visible = false)
	
	# While stamp fades, fly the snapshot to the pile
	# Slight random rotation so the pile looks messy
	var pile_tween = create_tween().set_parallel(true)
	var target_pos = pile_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	var target_rot = randf_range(-0.15, 0.15)  # radians, slight tilt
	
	pile_tween.tween_property(snapshot, "global_position", global_position + target_pos, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	pile_tween.tween_property(snapshot, "scale", Vector2(PILE_SCALE, PILE_SCALE), 0.4)
	pile_tween.tween_property(snapshot, "rotation", target_rot, 0.4)
	
	# --- Reset for next page ---
	_reset_grid()
	page_completed.emit(pages)
	print("PAGE %d COMPLETE!" % pages)
	
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
	
