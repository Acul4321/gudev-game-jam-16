extends Node

signal sfx_played(sfx_name: StringName)

const SFX_DIR: String = "res://assets/sfx"
const SUPPORTED_EXTENSIONS: PackedStringArray = ["wav", "ogg", "mp3"]
const SFX_BUS: StringName = &"Sfx"
const SFX_BUS_ALT: StringName = &"SFX"
const MASTER_BUS: StringName = &"Master"

@export_category("Settings")
@export var bus: String = ""
@export_range(1, 32, 1) var max_players: int = 12

var _clips: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player_idx: int = 0


func _ready() -> void:
	_setup_players()
	reload_sfx()


func reload_sfx() -> void:
	_clips.clear()
	_load_dir_recursive(SFX_DIR)


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


func _load_dir_recursive(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		push_warning("SFX directory not found: %s" % dir_path)
		return

	for subdir: String in dir.get_directories():
		_load_dir_recursive("%s/%s" % [dir_path, subdir])

	for file_name: String in dir.get_files():
		if not _is_supported_audio_file(file_name):
			continue

		var clip_path: String = "%s/%s" % [dir_path, file_name]
		var stream: AudioStream = load(clip_path) as AudioStream
		if stream == null:
			push_warning("Could not load sfx clip: %s" % clip_path)
			continue

		var key: StringName = StringName(file_name.get_basename())
		_clips[key] = stream


func _is_supported_audio_file(file_name: String) -> bool:
	var ext: String = file_name.get_extension().to_lower()
	return SUPPORTED_EXTENSIONS.has(ext)
