extends Node
class_name AudioManager

# Audio buses
const SFX_BUS := "Master/SFX"
const MUSIC_BUS := "Master/Music"

# Volume ranges (0.0 to 1.0)
var master_volume: float = 1.0 setget set_master_volume, get_master_volume
var music_volume: float = 0.7 setget set_music_volume, get_music_volume
var sfx_volume: float = 0.8 setget set_sfx_volume, get_sfx_volume

# SFX pool size
const SFX_POOL_SIZE := 10

# Audio players (we'll create them as children)
var _music_player: AudioStreamPlayer2D
var _sfx_players: Array[AudioStreamPlayer2D] = []

# Cached audio streams (optional, for quick play)
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}
# Generated beep sounds cache
var _beep_cache: Dictionary = {}

func _ready() -> void:
	# Ensure audio buses exist
	AudioServer.create_bus(SFX_BUS)
	AudioServer.create_bus(MUSIC_BUS)
	AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(sfx_volume))
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(music_volume))
	
	# Create music player
	_music_player = AudioStreamPlayer2D.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)
	
	# Pre-create SFX pool
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer2D.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)

# Volume setters
func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db("Master", linear_to_db(master_volume))

func get_master_volume() -> float:
	return master_volume

func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(music_volume * master_volume))

func get_music_volume() -> float:
	return music_volume

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(sfx_volume * master_volume))

func get_sfx_volume() -> float:
	return sfx_volume

# Helper: linear to decibel
func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return db_linear + 20.0 * log10(linear)

# Generate a beep sound as an AudioStreamSample
func _make_beep_stream(freq_hz: float, duration_sec: float, volume: float = 0.5) -> AudioStreamSample:
	var key = "%f_%f_%f" % [freq_hz, duration_sec, volume]
	if _beep_cache.has(key):
		return _beep_cache[key]
	var sample_rate := 44100
	var sample_count := int(sample_rate * duration_sec)
	var wave := Wave.new()
	wave.create_mono(sample_count)
	for i in sample_count:
		var t: float = i / sample_rate
		var sample: float = sin(2.0 * PI * freq_hz * t) * volume
		wave.set_sample(i, sample)
	var stream := AudioStreamSample.new()
	stream.data = wave
	_beep_cache[key] = stream
	return stream

# Play a one-shot SFX
func play_sfx(stream: AudioStream, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> void:
	if not stream:
		push_warning("AudioManager: play_sfx called with null stream")
		return
	
	# Find an inactive player from pool
	var player: AudioStreamPlayer2D = null
	for p in _sfx_players:
		if not p.playing:
			player = p
			break
	if not player:
		# If all busy, reuse the oldest (first)
		player = _sfx_players[0]
	
	player.stream = stream
	player.volume_scale = volume_scale * sfx_volume * master_volume
	player.pitch_scale = pitch_scale
	player.play()

# Play SFX by name (if cached)
func play_sfx_named(name: String, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> void:
	var stream := _sfx_cache.get(name)
	if stream:
		play_sfx(stream, volume_scale, pitch_scale)
	else:
		push_warning("AudioManager: SFX '%s' not cached" % name)

# Play music (streaming)
func play_music(stream: AudioStream, loop: boolean = true, fade_in_sec: float = 0.0) -> void:
	if not stream:
		push_warning("AudioManager: play_music called with null stream")
		return
	
	_music_player.stream = stream
	_music_player.loop = loop
	_music_player.volume_scale = music_volume * master_volume
	
	if fade_in_sec > 0:
		_music_player.volume_scale = 0
		_music_player.play()
		# Fade in using Tween
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_scale", music_volume * master_volume, fade_in_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_music_player.play()

# Stop music with optional fade out
func stop_music(fade_out_sec: float = 0.0) -> void:
	if fade_out_sec > 0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_scale", 0.0, fade_out_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(callable(_music_player.stop)).set_delay(fade_out_sec)
	else:
		_music_player.stop()

# Pause/resume music
func pause_music() -> void:
	_music_player.set_pause(true)

func resume_music() -> void:
	_music_player.set_pause(false)

# Check if music is playing
func is_music_playing() -> boolean:
	return _music_player.playing

# Preload and cache audio streams (call from init or autoload)
func preload_sfx(path: String, alias: String = null) -> void:
	var key := alias if alias else path
	var res := ResourceLoader.load(path)
	if res and res is AudioStream:
		_sfx_cache[key] = res
	else:
		push_error("AudioManager: Failed to load SFX at %s" % path)

func preload_music(path: String, alias: String = null) -> void:
	var key := alias if alias else path
	var res := ResourceLoader.load(path)
	if res and res is AudioStream:
		_music_cache[key] = res
	else:
		push_error("AudioManager: Failed to load music at %s" % path)

# Convenience: play common game events (placeholder using generated beep)
func play_player_hit() -> void:
	var beep := _make_beep_stream(440.0, 0.1, 0.5)  # A4 note, 100ms
	play_sfx(beep, 0.5, 1.0)

func play_enemy_death() -> void:
	var beep := _make_beep_stream(220.0, 0.3, 0.6)  # A3, 300ms
	play_sfx(beep, 0.7, 0.8)

func play_skill_cast(skill_type: String) -> void:
	var beep := _make_beep_stream(660.0, 0.07, 0.4)  # E5, 70ms
	play_sfx(beep, 0.4, 1.2)

func level_up() -> void:
	var beep1 := _make_beep_stream(523.25, 0.1, 0.5)  # C5
	var beep2 := _make_beep_stream(659.25, 0.1, 0.5)  # E5
	var beep3 := _make_beep_stream(783.99, 0.1, 0.5)  # G5
	play_sfx(beep1, 0.5, 1.0)
	yield(get_tree().create_timer(0.1), "timeout")
	play_sfx(beep2, 0.5, 1.0)
	yield(get_tree().create_timer(0.1), "timeout")
	play_sfx(beep3, 0.5, 1.0)

func boss_warning() -> void:
	var beep := _make_beep_stream(110.0, 0.5, 0.8)  # A2, 500ms
	play_sfx(beep, 0.8, 0.5)