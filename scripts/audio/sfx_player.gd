extends Node

# Procedural audio bus.
# - Generates short 16-bit PCM samples for each event at startup.
# - Plays them through a pool of AudioStreamPlayer nodes.
# - Replace the procedural samples with real .wav/.ogg streams when art is ready
#   by editing _build_samples().

const SAMPLE_RATE: int = 44100
const POOL_SIZE: int = 6

const ID_GOAL_HORN: String = "goal_horn"
const ID_CHECK_HIT: String = "check_hit"
const ID_UI_CLICK: String = "ui_click"
const ID_UI_FOCUS: String = "ui_focus"
const ID_REWARD_PICK: String = "reward_pick"
const ID_PERIOD_END: String = "period_end"
const ID_MATCH_WIN: String = "match_win"
const ID_CROWD_CHEER: String = "crowd_cheer"
const ID_SAVE_THUMP: String = "save_thump"
const ID_WHISTLE: String = "whistle"

var sfx_volume_db: float = -4.0
var music_volume_db: float = -8.0
var master_volume_db: float = 0.0

var _samples: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0

func _ready() -> void:
	_build_samples()
	_build_player_pool()

func play(sfx_id: String, pitch: float = 1.0, volume_offset_db: float = 0.0) -> void:
	if not _samples.has(sfx_id):
		return
	var player: AudioStreamPlayer = _pick_player()
	if player == null:
		return
	player.stream = _samples[sfx_id]
	player.pitch_scale = pitch
	player.volume_db = sfx_volume_db + master_volume_db + volume_offset_db
	player.play()

func set_master_volume(db: float) -> void:
	master_volume_db = db

func set_sfx_volume(db: float) -> void:
	sfx_volume_db = db

func set_music_volume(db: float) -> void:
	music_volume_db = db

func _pick_player() -> AudioStreamPlayer:
	if _players.is_empty():
		return null
	for offset in range(POOL_SIZE):
		var idx: int = (_next_player + offset) % POOL_SIZE
		var candidate: AudioStreamPlayer = _players[idx]
		if not candidate.playing:
			_next_player = (idx + 1) % POOL_SIZE
			return candidate
	# All busy — steal the next one.
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	return player

func _build_player_pool() -> void:
	for i in range(POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func _build_samples() -> void:
	_samples[ID_GOAL_HORN] = _make_horn_blat(1.4, 110.0, 82.0)
	_samples[ID_CHECK_HIT] = _make_noise_burst(0.18, 0.78, 0.045)
	_samples[ID_UI_CLICK] = _make_tone(0.05, 820.0, 0.55, 0.012, 0.02)
	_samples[ID_UI_FOCUS] = _make_tone(0.06, 540.0, 0.4, 0.005, 0.03)
	_samples[ID_REWARD_PICK] = _make_chime([523.25, 659.25, 783.99], 0.16)
	_samples[ID_PERIOD_END] = _make_descending_whistle(0.85, 880.0, 320.0)
	_samples[ID_MATCH_WIN] = _make_chime([523.25, 659.25, 783.99, 1046.50], 0.22)
	_samples[ID_CROWD_CHEER] = _make_crowd_swell(1.9, 0.62)
	_samples[ID_SAVE_THUMP] = _make_noise_burst(0.11, 0.62, 0.008)
	_samples[ID_WHISTLE] = _make_ref_whistle(0.55, 2350.0)

# ---------- waveform helpers ----------

func _make_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = _floats_to_pcm16(samples)
	return stream

func _floats_to_pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v: float = clamp(samples[i], -1.0, 1.0)
		var s16: int = int(v * 32767.0)
		if s16 < 0:
			s16 += 65536
		bytes[i * 2] = s16 & 0xFF
		bytes[i * 2 + 1] = (s16 >> 8) & 0xFF
	return bytes

func _adsr(amount: int, attack: float, release: float) -> PackedFloat32Array:
	var env: PackedFloat32Array = PackedFloat32Array()
	env.resize(amount)
	var attack_samples: int = int(attack * SAMPLE_RATE)
	var release_samples: int = int(release * SAMPLE_RATE)
	for i in range(amount):
		var a: float = 1.0
		if i < attack_samples and attack_samples > 0:
			a = float(i) / float(attack_samples)
		elif i > amount - release_samples and release_samples > 0:
			a = float(amount - i) / float(release_samples)
		env[i] = clamp(a, 0.0, 1.0)
	return env

func _make_tone(duration: float, freq: float, amp: float, attack: float = 0.005, release: float = 0.05) -> AudioStreamWAV:
	var count: int = int(duration * SAMPLE_RATE)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var env: PackedFloat32Array = _adsr(count, attack, release)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		samples[i] = sin(TAU * freq * t) * amp * env[i]
	return _make_stream(samples)

func _make_chime(freqs: Array, note_duration: float) -> AudioStreamWAV:
	var per_note: int = int(note_duration * SAMPLE_RATE)
	var total: int = per_note * freqs.size()
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(total)
	for n in range(freqs.size()):
		var freq: float = float(freqs[n])
		var env: PackedFloat32Array = _adsr(per_note, 0.005, note_duration * 0.6)
		for i in range(per_note):
			var t: float = float(i) / float(SAMPLE_RATE)
			var v: float = sin(TAU * freq * t) * 0.55 + sin(TAU * freq * 2.0 * t) * 0.18
			samples[n * per_note + i] = v * env[i]
	return _make_stream(samples)

func _make_noise_burst(duration: float, amp: float, attack: float) -> AudioStreamWAV:
	var count: int = int(duration * SAMPLE_RATE)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var env: PackedFloat32Array = _adsr(count, attack, duration * 0.85)
	var last: float = 0.0
	for i in range(count):
		# Low-passed white noise for a chunkier thud.
		var n: float = randf() * 2.0 - 1.0
		last = last * 0.55 + n * 0.45
		samples[i] = last * amp * env[i]
	return _make_stream(samples)

func _make_descending_whistle(duration: float, freq_start: float, freq_end: float) -> AudioStreamWAV:
	var count: int = int(duration * SAMPLE_RATE)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var env: PackedFloat32Array = _adsr(count, 0.02, duration * 0.4)
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(count)
		var freq: float = lerp(freq_start, freq_end, t)
		phase += TAU * freq / float(SAMPLE_RATE)
		samples[i] = sin(phase) * 0.5 * env[i]
	return _make_stream(samples)

func _make_horn_blat(duration: float, freq_low: float, freq_high: float) -> AudioStreamWAV:
	var count: int = int(duration * SAMPLE_RATE)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var env: PackedFloat32Array = _adsr(count, 0.012, duration * 0.35)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		# Two slightly detuned sawtooth-ish waves stacked for a thick blat.
		var a: float = _saw_wave(freq_low * t) * 0.45
		var b: float = _saw_wave(freq_high * t) * 0.32
		var sub: float = sin(TAU * freq_low * 0.5 * t) * 0.20
		samples[i] = (a + b + sub) * env[i]
	return _make_stream(samples)

func _saw_wave(phase: float) -> float:
	return 2.0 * (phase - floor(phase + 0.5))

# Band-passed noise that swells in and tails out — reads as a crowd roar.
func _make_crowd_swell(duration: float, amp: float) -> AudioStreamWAV:
	var count: int = int(duration * SAMPLE_RATE)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var env: PackedFloat32Array = _adsr(count, duration * 0.22, duration * 0.55)
	var last: float = 0.0
	var slow: float = 0.0
	for i in range(count):
		var n: float = randf() * 2.0 - 1.0
		last = last * 0.82 + n * 0.18
		slow = slow * 0.9992 + (randf() * 2.0 - 1.0) * 0.0008
		samples[i] = (last + slow * 24.0) * amp * env[i]
	return _make_stream(samples)

# Referee whistle: strong tone with a fast trill.
func _make_ref_whistle(duration: float, freq: float) -> AudioStreamWAV:
	var count: int = int(duration * SAMPLE_RATE)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var env: PackedFloat32Array = _adsr(count, 0.01, duration * 0.3)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var trill: float = 1.0 + 0.012 * sin(TAU * 38.0 * t)
		samples[i] = (sin(TAU * freq * trill * t) * 0.42 + sin(TAU * freq * 1.5 * t) * 0.10) * env[i]
	return _make_stream(samples)
