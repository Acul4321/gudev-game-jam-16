extends Node

signal song_changed(song_name: StringName)
signal all_music_finished

# Emit this signal to play one song by name.
signal play_song(song_name: StringName, is_looping: bool, is_fading: bool, fade_time: float)

# Emit this signal to play a playlist of song names.
signal play_playlist(playlist: Array, is_looping: bool, is_shuffling: bool, is_fading: bool, fade_time: float)

signal stop_music
signal pause_music
signal resume_music

const MUSIC_DIR: String = "res://assets/music"
const SUPPORTED_EXTENSIONS: PackedStringArray = ["wav", "ogg", "mp3"]
const MUSIC_BUS: StringName = &"Music"
const MASTER_BUS: StringName = &"Master"
const SILENT_DB: float = -40.0

var is_crossfading: bool = false
var is_looping_song: bool = false
var is_looping_playlist: bool = false
var crossfade_time: float = 1.0

var current_song_idx: int = 0
var current_song: StringName = &""
var current_playlist: Array[StringName] = []
var current_player: AudioStreamPlayer

var _tracks: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _active_player_idx: int = 0
var _crossfade_tween: Tween

@export_category("Settings")
@export var bus: String = ""

@onready var song_timer: Timer = Timer.new()


func _ready() -> void:
	_setup_players()
	_setup_timer()
	reload_tracks()

	play_song.connect(_on_play_song)
	play_playlist.connect(_on_play_playlist)
	stop_music.connect(_on_stop_music)
	pause_music.connect(_on_pause_music)
	resume_music.connect(_on_resume_music)


func reload_tracks() -> void:
	_tracks.clear()

	var dir: DirAccess = DirAccess.open(MUSIC_DIR)
	if dir == null:
		push_warning("Music directory not found: %s" % MUSIC_DIR)
		return

	var files: PackedStringArray = dir.get_files()
	files.sort()

	for file_name: String in files:
		if not _is_supported_audio_file(file_name):
			continue

		var track_path: String = "%s/%s" % [MUSIC_DIR, file_name]
		var stream: AudioStream = load(track_path) as AudioStream
		if stream == null:
			push_warning("Could not load track: %s" % track_path)
			continue

		var key: StringName = StringName(file_name.get_basename())
		_tracks[key] = stream


func play(track_name: StringName, loop: bool = true, volume_db: float = 0.0) -> bool:
	if not _tracks.has(track_name):
		push_warning("Unknown music track: %s" % String(track_name))
		return false

	is_looping_song = loop
	is_looping_playlist = false
	is_crossfading = false
	current_playlist.clear()
	current_song = track_name

	_play_immediate(track_name, volume_db)
	return true


func stop() -> void:
	_on_stop_music()


func pause() -> void:
	_on_pause_music()


func resume() -> void:
	_on_resume_music()


func set_volume(volume_db: float) -> void:
	for player in _players:
		if player.playing or player.stream_paused:
			player.volume_db = volume_db


func is_playing() -> bool:
	for player in _players:
		if player.playing:
			return true
	return false


func get_current_track() -> StringName:
	return current_song


func get_track_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for key in _tracks.keys():
		names.append(String(key))
	names.sort()
	return names


func _on_play_song(song_name: StringName, looping: bool, fading: bool, fade_time: float) -> void:
	if not _tracks.has(song_name):
		push_warning("Unknown music track: %s" % String(song_name))
		return

	current_song = song_name
	is_looping_song = looping
	is_looping_playlist = false
	current_playlist.clear()
	is_crossfading = fading
	crossfade_time = fade_time

	if is_crossfading:
		_change_with_crossfade(song_name)
	else:
		_play_immediate(song_name, 0.0)


func _on_play_playlist(playlist: Array, looping: bool, shuffling: bool, fading: bool, fade_time: float) -> void:
	var normalized_playlist: Array[StringName] = []
	for item in playlist:
		var key: StringName = StringName(str(item))
		if _tracks.has(key):
			normalized_playlist.append(key)

	if normalized_playlist.is_empty():
		push_warning("Playlist is empty or contains no valid tracks")
		return

	if shuffling:
		normalized_playlist.shuffle()

	current_playlist = normalized_playlist
	current_song_idx = 0
	current_song = current_playlist[current_song_idx]
	is_looping_song = false
	is_looping_playlist = looping
	is_crossfading = fading
	crossfade_time = fade_time

	if is_crossfading:
		_change_with_crossfade(current_song)
	else:
		_play_immediate(current_song, 0.0)


func _change_with_crossfade(song_name: StringName) -> void:
	var incoming_idx: int = 1 - _active_player_idx
	var incoming_player: AudioStreamPlayer = _players[incoming_idx]
	var outgoing_player: AudioStreamPlayer = _players[_active_player_idx]
	var stream: AudioStream = _tracks[song_name] as AudioStream

	if stream == null:
		return

	if _crossfade_tween != null:
		_crossfade_tween.kill()

	var fade: float = clampf(crossfade_time, 0.25, 4.0)
	incoming_player.stream = stream
	incoming_player.volume_db = SILENT_DB
	incoming_player.stream_paused = false
	incoming_player.play()

	_crossfade_tween = create_tween()
	_crossfade_tween.tween_property(incoming_player, "volume_db", 0.0, fade)
	_crossfade_tween.parallel().tween_property(outgoing_player, "volume_db", SILENT_DB, fade)
	_crossfade_tween.finished.connect(func() -> void:
		if outgoing_player.playing:
			outgoing_player.stop()
	)

	_active_player_idx = incoming_idx
	current_player = incoming_player
	current_song = song_name
	_start_song_timer(stream, fade)
	song_changed.emit(song_name)


func _play_immediate(song_name: StringName, volume_db: float) -> void:
	_on_stop_music()

	var stream: AudioStream = _tracks[song_name] as AudioStream
	if stream == null:
		return

	var player: AudioStreamPlayer = _players[0]
	player.stream = stream
	player.volume_db = volume_db
	player.stream_paused = false
	player.play()

	_active_player_idx = 0
	current_player = player
	current_song = song_name
	_start_song_timer(stream, 0.0)
	song_changed.emit(song_name)


func _on_stop_music() -> void:
	for player in _players:
		if player.playing:
			player.stop()
		player.stream_paused = false
		player.volume_db = 0.0

	if not song_timer.is_stopped():
		song_timer.stop()

	current_song = &""
	current_song_idx = 0
	current_playlist.clear()


func _on_pause_music() -> void:
	for player in _players:
		if player.playing:
			player.stream_paused = true

	if not song_timer.is_stopped():
		song_timer.paused = true


func _on_resume_music() -> void:
	for player in _players:
		if player.stream_paused:
			player.stream_paused = false

	if not song_timer.is_stopped():
		song_timer.paused = false


func _on_song_timer_timeout() -> void:
	if is_looping_song and not current_song.is_empty():
		play_song.emit(current_song, is_looping_song, is_crossfading, crossfade_time)
		return

	if current_playlist.is_empty():
		current_song = &""
		current_song_idx = 0
		all_music_finished.emit()
		return

	current_song_idx += 1
	if current_song_idx >= current_playlist.size():
		if is_looping_playlist:
			current_song_idx = 0
		else:
			current_playlist.clear()
			current_song = &""
			current_song_idx = 0
			all_music_finished.emit()
			return

	var next_song: StringName = current_playlist[current_song_idx]
	if is_crossfading:
		_change_with_crossfade(next_song)
	else:
		_play_immediate(next_song, 0.0)


func _setup_players() -> void:
	for i: int in range(2):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "MusicPlayer%d" % (i + 1)
		player.bus = _resolve_bus()
		add_child(player)
		_players.append(player)

	current_player = _players[_active_player_idx]


func _setup_timer() -> void:
	song_timer.name = "SongTimer"
	song_timer.one_shot = true
	song_timer.autostart = false
	add_child(song_timer)
	song_timer.timeout.connect(_on_song_timer_timeout)


func _resolve_bus() -> StringName:
	if not bus.is_empty() and AudioServer.get_bus_index(StringName(bus)) != -1:
		return StringName(bus)
	if AudioServer.get_bus_index(MUSIC_BUS) != -1:
		return MUSIC_BUS
	return MASTER_BUS


func _start_song_timer(stream: AudioStream, fade: float) -> void:
	var length: float = maxf(stream.get_length() - fade, 0.01)
	song_timer.start(length)


func _is_supported_audio_file(file_name: String) -> bool:
	var ext: String = file_name.get_extension().to_lower()
	return SUPPORTED_EXTENSIONS.has(ext)
