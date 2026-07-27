extends Node
class_name AudioManager

## VS modunda ses sistemi basit beep sesleriyle sinirli.
## Gercek ses dosyalari henuz eklenmedi.

var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8

var _beep_cache: Dictionary = {}

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)

func get_master_volume() -> float:
	return master_volume

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)

func get_music_volume() -> float:
	return music_volume

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)

func get_sfx_volume() -> float:
	return sfx_volume

func _make_beep_stream(freq_hz: float, duration_sec: float, volume: float = 0.5) -> AudioStreamWAV:
	var key: String = "%f_%f_%f" % [freq_hz, duration_sec, volume]
	if _beep_cache.has(key):
		return _beep_cache[key]
	var sample_rate := 44100
	var sample_count := int(sample_rate * duration_sec)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t: float = i / sample_rate
		var sample: float = sin(2.0 * PI * freq_hz * t) * volume
		var val: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, val)
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	_beep_cache[key] = stream
	return stream

func _get_sfx_player() -> AudioStreamPlayer2D:
	var p := AudioStreamPlayer2D.new()
	add_child(p)
	return p

func play_sfx(stream: AudioStream, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> void:
	if not stream:
		return
	var player := _get_sfx_player()
	player.stream = stream
	player.volume_db = linear_to_db(volume_scale * sfx_volume * master_volume)
	player.pitch_scale = pitch_scale
	player.play()
	await player.finished
	if is_instance_valid(player):
		player.queue_free()

func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

func play_player_hit() -> void:
	var beep := _make_beep_stream(440.0, 0.1, 0.5)
	play_sfx(beep, 0.5, 1.0)

func play_enemy_death() -> void:
	var beep := _make_beep_stream(220.0, 0.3, 0.6)
	play_sfx(beep, 0.7, 0.8)

func play_skill_cast(skill_type: String) -> void:
	var beep := _make_beep_stream(660.0, 0.07, 0.4)
	play_sfx(beep, 0.4, 1.2)

func level_up() -> void:
	var beep1 := _make_beep_stream(523.25, 0.1, 0.5)
	var beep2 := _make_beep_stream(659.25, 0.1, 0.5)
	var beep3 := _make_beep_stream(783.99, 0.1, 0.5)
	play_sfx(beep1, 0.5, 1.0)
	await get_tree().create_timer(0.1).timeout
	play_sfx(beep2, 0.5, 1.0)
	await get_tree().create_timer(0.1).timeout
	play_sfx(beep3, 0.5, 1.0)

func boss_warning() -> void:
	var beep := _make_beep_stream(110.0, 0.5, 0.8)
	play_sfx(beep, 0.8, 0.5)
