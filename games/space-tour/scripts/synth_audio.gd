class_name SynthAudio
extends Node
## All audio is synthesised in code (no asset files): soft bell notes on a pentatonic
## scale (so any sequence sounds pleasant) (the app's theme track is the only background music).

const RATE := 22050
const NOTES := [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66]   # C major pentatonic

var _bells: Array[AudioStreamWAV] = []
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for f in NOTES:
		_bells.append(_make_bell(f))
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.volume_db = -9.0
		add_child(p)
		_players.append(p)
	# No ambient pad: the app's one theme track is the only music.


func play_note(index: int) -> void:
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _bells[clampi(index, 0, _bells.size() - 1)]
	p.play()


## Gentle rising arpeggio for milestones.
func play_chime() -> void:
	for i in [0, 2, 4, 6]:
		play_note(i)
		await get_tree().create_timer(0.14).timeout


func _make_bell(freq: float) -> AudioStreamWAV:
	var n := int(RATE * 1.4)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 3.2) * minf(t * 200.0, 1.0)
		var v := sin(TAU * freq * t)
		v += 0.35 * sin(TAU * freq * 2.0 * t) * exp(-t * 2.0)
		v += 0.12 * sin(TAU * freq * 3.01 * t) * exp(-t * 4.0)
		data.encode_s16(i * 2, int(clampf(v * env * 0.35, -1.0, 1.0) * 32767.0))
	return _wav(data, false, 0)


## 4-second seamless loop: every partial completes a whole number of cycles.
func _make_pad() -> AudioStreamWAV:
	var n := RATE * 4
	var data := PackedByteArray()
	data.resize(n * 2)
	var freqs := [110.0, 165.0, 220.0, 277.5, 330.0]
	var amps := [0.5, 0.35, 0.3, 0.2, 0.18]
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for k in freqs.size():
			var lfo := 0.75 + 0.25 * sin(TAU * t / 4.0 * float(k % 2 + 1) + k)
			v += sin(TAU * freqs[k] * t) * amps[k] * lfo
		data.encode_s16(i * 2, int(clampf(v * 0.3, -1.0, 1.0) * 32767.0))
	return _wav(data, true, n)


func _wav(data: PackedByteArray, loop: bool, loop_end: int) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = loop_end
	return w
