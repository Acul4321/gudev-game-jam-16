extends Node

signal sfx_played(sfx_name: StringName)

const SFX_BUS: StringName = &"Sfx"
const SFX_BUS_ALT: StringName = &"SFX"
const MASTER_BUS: StringName = &"Master"

const CLIPS: Dictionary = {
	&"basePickup": preload("res://assets/sfx/basePickup.wav"),
	&"catActive": preload("res://assets/sfx/catActive.wav"),
	&"meow": preload("res://assets/sfx/meow.wav"),
	&"pencil-scribble": preload("res://assets/sfx/pencil-scribble.wav"),
	&"phoneRing": preload("res://assets/sfx/phoneRing.wav"),
}

@export_category("Settings")
@export var bus: String = ""
@export_range(1, 32, 1) var max_players: int = 12

var _clips: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player_idx: int = 0


func _ready() -> void:
	_clips = CLIPS.duplicate()
	_setup_players()


func reload_sfx() -> void:
	_clips = CLIPS.duplicate()


func play(sfx_name: StringName, volume_db: float = 0.0, pitch_scale: float = 1.0) -> bool:
	if not _clips.has(sfx_name):
		push_warning("Unknown sfx clip: %s" % String(sfx_name))
		return false

	if _players.is_empty():
		return false

	var clip: AudioStream = _clips[sfx_name] as AudioStream
	if clip == null:
		return false

	var player: AudioStreamPlayer = _players[_next_player_idx]
	_next_player_idx = (_next_player_idx + 1) % _players.size()

	player.stream = clip
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.stream_paused = false
	player.play()

	sfx_played.emit(sfx_name)
	return true


func stop_all() -> void:
	for player in _players:
		if player.playing:
			player.stop()


func set_volume(volume_db: float) -> void:
	for player in _players:
		player.volume_db = volume_db


func get_clip_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for key in _clips.keys():
		names.append(String(key))
	names.sort()
	return names


func has_clip(sfx_name: StringName) -> bool:
	return _clips.has(sfx_name)


func _setup_players() -> void:
	for player in _players:
		if is_instance_valid(player):
			player.queue_free()

	_players.clear()
	_next_player_idx = 0

	for i: int in range(max_players):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % (i + 1)
		player.bus = _resolve_bus()
		add_child(player)
		_players.append(player)


func _resolve_bus() -> StringName:
	if not bus.is_empty() and AudioServer.get_bus_index(StringName(bus)) != -1:
		return StringName(bus)
	if AudioServer.get_bus_index(SFX_BUS) != -1:
		return SFX_BUS
	if AudioServer.get_bus_index(SFX_BUS_ALT) != -1:
		return SFX_BUS_ALT
	return MASTER_BUS
