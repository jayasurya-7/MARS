class_name SortSfx
extends Node
## Tiny synthesized sound effects (no audio assets needed). Soft, non-startling tones.

const RATE := 22050
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _notes: Array[AudioStreamWAV] = []
## Pentatonic scale (G4..A6): each correct sort plays the next note, so a game builds a little tune.
const SCALE := [392.0, 440.0, 523.0, 587.0, 659.0, 784.0, 880.0, 1047.0, 1175.0, 1319.0, 1568.0, 1760.0]


func _ready() -> void:
	_streams["pick"] = _tone([587.0], 0.10, 0.22)
	_streams["good"] = _tone([659.0, 880.0, 1319.0], 0.11, 0.30)
	_streams["oops"] = _tone([392.0, 330.0], 0.16, 0.22)
	_streams["win"] = _tone([523.0, 659.0, 784.0, 1047.0, 784.0, 1047.0, 1319.0], 0.17, 0.30)
	_streams["full"] = _tone([784.0, 988.0, 1175.0, 1568.0], 0.12, 0.22)
	for f: float in SCALE:
		_notes.append(_tone([f, f * 1.5], 0.13, 0.22))
	for i in 4:
		var pl := AudioStreamPlayer.new()
		add_child(pl)
		_players.append(pl)


func play(sound: String) -> void:
	if _streams.has(sound):
		_play_stream(_streams[sound])


func play_note(i: int) -> void:
	_play_stream(_notes[clampi(i, 0, _notes.size() - 1)])


func _play_stream(stream: AudioStream) -> void:
	var pl := _players[_next]
	_next = (_next + 1) % _players.size()
	pl.stream = stream
	pl.play()


func _tone(notes: Array, note_len: float, vol: float) -> AudioStreamWAV:
	var n_per := int(note_len * RATE)
	var data := PackedByteArray()
	data.resize(n_per * notes.size() * 2)
	for ni in notes.size():
		var f: float = notes[ni]
		for i in n_per:
			var t := float(i) / RATE
			var env := exp(-t * 5.0) * minf(1.0, i / 80.0) * minf(1.0, (n_per - i) / 220.0)
			var v := (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)) * env * vol
			data.encode_s16((ni * n_per + i) * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
