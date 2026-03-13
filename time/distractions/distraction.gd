extends Area2D

@export var force_open_delay: float = 2.0
@export var throw_drag: float = 1200.0
@export var offscreen_padding: float = 96.0
@export var distractionResource: DistractionResource

@onready var sprite: Sprite2D = $Visual

var _base_sprite_scale: Vector2 = Vector2.ONE
var _activated: bool = false
var _grabbed: bool = false
var _thrown: bool = false
var _velocity: Vector2 = Vector2.ZERO
var _grab_offset: Vector2 = Vector2.ZERO
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _last_sample_time: float = 0.0


func _ready() -> void:
	add_to_group("distractions")
	input_pickable = true
	_base_sprite_scale = sprite.scale
	_apply_before_active_sprite()
	_apply_before_active_scale()
	_play_before_active_sfx()
	_monitor_throw_velocity(get_global_mouse_position())
	var activation_delay: float = _get_activation_delay()
	if activation_delay <= 0.0:
		_activate()
	else:
		var timer := get_tree().create_timer(activation_delay)
		timer.timeout.connect(_activate)


func _process(delta: float) -> void:
	if _grabbed:
		var mouse_pos := get_global_mouse_position()
		global_position = mouse_pos + _grab_offset
		_monitor_throw_velocity(mouse_pos)
		return

	if _thrown:
		global_position += _velocity * delta
		_velocity = _velocity.move_toward(Vector2.ZERO, throw_drag * delta)
		if _is_outside_screen():
			queue_free()


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _activated:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if Game.is_hand_open() or Game.is_hand_grabbing():
				_start_grab()
				get_viewport().set_input_as_handled()
		else:
			if _grabbed:
				_release_throw()
				get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# Release throw even when the cursor is no longer over the collision shape.
	if _grabbed and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_release_throw()


func _exit_tree() -> void:
	if _activated:
		Game.end_distraction_force_open()


func _activate() -> void:
	if _activated:
		return
	_activated = true
	Game.begin_distraction_force_open()
	_apply_after_active_sprite()
	_apply_after_active_scale()
	_play_after_active_sfx()
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _start_grab() -> void:
	_grabbed = true
	_thrown = false
	_velocity = Vector2.ZERO
	_apply_grabbing_sprite()
	_apply_grabbing_scale()
	_play_grabbing_sfx()
	var mouse_pos := get_global_mouse_position()
	_grab_offset = global_position - mouse_pos
	_monitor_throw_velocity(mouse_pos)
	Game.set_hand_grab()


func _release_throw() -> void:
	_grabbed = false
	_thrown = true
	_apply_after_active_sprite()
	_apply_after_active_scale()
	Game.set_hand_open()


func _monitor_throw_velocity(mouse_pos: Vector2) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if _last_sample_time > 0.0:
		var dt: float = maxf(now - _last_sample_time, 0.001)
		_velocity = (mouse_pos - _last_mouse_pos) / dt
	_last_sample_time = now
	_last_mouse_pos = mouse_pos


func _is_outside_screen() -> bool:
	var padded_rect := get_viewport().get_visible_rect().grow(offscreen_padding)
	return not padded_rect.has_point(global_position)


func _get_activation_delay() -> float:
	if distractionResource:
		return distractionResource.durationBeforeActive
	return force_open_delay


func _apply_before_active_sprite() -> void:
	if distractionResource and distractionResource.beforeActiveSprite:
		sprite.texture = distractionResource.beforeActiveSprite


func _apply_after_active_sprite() -> void:
	if distractionResource and distractionResource.afterActiveSprite:
		sprite.texture = distractionResource.afterActiveSprite


func _apply_grabbing_sprite() -> void:
	if not distractionResource:
		return

	if distractionResource.grabbingSprite:
		sprite.texture = distractionResource.grabbingSprite
	elif distractionResource.afterActiveSprite:
		sprite.texture = distractionResource.afterActiveSprite


func _apply_before_active_scale() -> void:
	if not distractionResource:
		return

	var factor: float = distractionResource.beforeActiveScaleFactor
	if is_equal_approx(factor, 1.0):
		factor = distractionResource.scaleFactor
	sprite.scale = _base_sprite_scale * factor


func _apply_after_active_scale() -> void:
	if not distractionResource:
		return

	var factor: float = distractionResource.afterActiveScaleFactor
	if is_equal_approx(factor, 1.0):
		factor = distractionResource.scaleFactor
	sprite.scale = _base_sprite_scale * factor


func _apply_grabbing_scale() -> void:
	if not distractionResource:
		return

	var factor: float = distractionResource.grabbingScaleFactor
	if is_equal_approx(factor, 1.0):
		if not is_equal_approx(distractionResource.afterActiveScaleFactor, 1.0):
			factor = distractionResource.afterActiveScaleFactor
		else:
			factor = distractionResource.scaleFactor
	sprite.scale = _base_sprite_scale * factor


func _play_before_active_sfx() -> void:
	if not distractionResource:
		return
	_play_sfx_name(distractionResource.beforeActiveSfxName)


func _play_after_active_sfx() -> void:
	if not distractionResource:
		return
	_play_sfx_name(distractionResource.afterActiveSfxName)


func _play_grabbing_sfx() -> void:
	if not distractionResource:
		return

	if not distractionResource.grabbingSfxName.is_empty():
		_play_sfx_name(distractionResource.grabbingSfxName)
		return

	# Backward compatibility for older resources.
	_play_sfx_name(distractionResource.pickupSfxName)


func _play_sfx_name(sfx_name: String) -> void:
	if sfx_name.is_empty():
		return
	Sfx.play(StringName(sfx_name))
