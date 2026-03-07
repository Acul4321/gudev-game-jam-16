extends Node2D

const GRID_W: int = 10
const GRID_H: int = 10
const FILL_THRESHOLD: float = 0.65

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
	# Remove all Line2D children (the strokes)
	for child in get_children():
		if child is Line2D:
			child.queue_free()
	current_line = null
	_reset_grid()
	is_drawing = false
	last_fill_pos = Vector2(-1, -1)
	page_completed.emit(pages)
	print("PAGE %d COMPLETE!" % pages)
	
