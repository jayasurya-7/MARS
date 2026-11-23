extends Node2D
# 60-second ironing game. Hold the mouse / finger and swipe the iron over the garment:
# the wrinkled "before" picture is revealed into the smooth "after" picture as you iron.
# Finished garments fly onto the clothes rail and the next one appears automatically.
#
# In MARS HOMER (game "IR", combined movement, patient-paced): each garment is one target, ironed
# smooth = hit. The app runs the 60 s and shows time and score, so the game's own timer, score card
# and pause button are off. The iron follows the hand (GamePointer); it irons just by moving.

const GAME_TIME := 60.0                      # strict 1-minute session
const IRON_RX := 100.0                       # iron footprint (smaller iron: more of the garment to reach)
const IRON_RY := 44.0
const IRON_RATE := 0.0075                    # how fast wrinkles disappear per pixel moved
const DONE_AT := 0.90                        # garment counts as done at 90 % smooth
const GUIDE_IDLE := 1.5                      # seconds without progress before the guide appears
const PRAISE := ["SPOTLESS!", "GREAT JOB!", "WELL DONE!", "SUPER!", "AMAZING!", "PERFECT!"]
const CELL_SRC := 17.0                       # wrinkle-grid cell size in sprite pixels
const GARMENTS := ["pink", "blue_dot", "plaid", "purple", "polo", "red", "floral", "suit", "kurta"]

const BOARD_SCALE := 0.88
const BOARD_POS := Vector2(380, 178)
const GARMENT_POS := Vector2(965, 505)
const GARMENT_ROT := 1.27                    # neck points up-right along the board
const SQUASH := 0.84                         # cross-board foreshortening
const GARMENT_LEN := 860.0
const IRON_SCALE := 0.38
const IRON_ANCHOR := Vector2(210, 365)       # sole centre inside iron.png
const IRON_ANG := -0.2
const RAIL_Y := 330.0
const RAIL_SLOTS := 5

const GARMENT_SHADER := """
shader_type canvas_item;
uniform sampler2D after_tex : filter_linear, repeat_disable;
uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform vec2 mask_scale = vec2(1.0);
uniform float fade = 1.0;
void fragment() {
	vec4 b = texture(TEXTURE, UV);
	vec4 a = texture(after_tex, UV);
	float m = smoothstep(0.1, 0.9, texture(mask_tex, UV * mask_scale).r);
	float al = mix(b.a, a.a, m);
	vec3 c = mix(b.rgb * b.a, a.rgb * a.a, m) / max(al, 0.001);
	// pulsing warm glow + shine on still-wrinkled areas so the player sees where to iron
	float need = (1.0 - m) * b.a;
	float pulse = 0.5 + 0.5 * sin(TIME * 4.0);
	float lum = dot(b.rgb, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(1.0, 0.92, 0.45), need * (0.16 + 0.20 * pulse));
	COLOR = vec4(c, al * fade);
}
"""

var font: Font
var sb := StyleBoxFlat.new()
var rng := RandomNumberGenerator.new()

# nodes drawn behind this node (board -> garment -> this node's iron/UI)
var shade: Node2D
var layer: Node2D
var mat: ShaderMaterial
var tex_iron: Texture2D

# current garment
var g_name := "pink"
var g_before: Texture2D
var g_after: Texture2D
var g_size := Vector2.ONE
var g_scale := Vector2.ONE
var cols := 0
var rows := 0
var wr := PackedFloat32Array()
var valid := PackedByteArray()
var valid_n := 0
var cell_scr := PackedVector2Array()
var mask_img: Image
var mask_tex: ImageTexture
var mask_dirty := true
var g_pop := 0.0
var bag: Array = []
## The area of the current garment. On the MARS device the patient's whole assessed range is spread
## over it, so every part of the garment can be reached and ironed.
var reach_rect := Rect2(380, 178, 1160, 700)

# game state
var state := "play"
var started := false
var paused := false
var fx_on := true
var time_left := GAME_TIME
var score := 0.0
var disp_score := 0.0
var score_pop := 0.0
var progress := 0.0
var disp_progress := 0.0
var ironed_count := 0
var best := 0
var over_t := 0.0
var time := 0.0

# iron
var iron_pos := Vector2(1000, 700)
var target := Vector2(1000, 700)
var iron_vel := Vector2.ZERO
var pressing := false

var steam: Array = []
var sparkles: Array = []
var popups: Array = []
var flyers: Array = []
var hung: Array = []
var hung_total := 0

var b_pause := Rect2(1723, 55, 130, 130)
var b_again := Rect2(730, 745, 460, 100)
var b_resume := Rect2(790, 600, 340, 110)

# guidance / feedback
var idle_t := 0.0
var guide_cell := -1
var guide_scan := 0.0
var said_half := false
var said_almost := false
var last_tick := -1

# sound
var snd_hiss: AudioStreamPlayer
var snd_fx: Array = []
var wav_chime: AudioStreamWAV
var wav_ding: AudioStreamWAV
var wav_tick: AudioStreamWAV
var wav_end: AudioStreamWAV
var wav_pop: AudioStreamWAV


func _ready() -> void:
	rng.randomize()
	# The app's feedback face (Titan One): the game's text is its big, friendly praise.
	font = preload("res://core/ui_theme.gd").DISPLAY
	load_best()
	tex_iron = load("res://games/ironing/assets/iron.png")
	setup_audio()

	# floor shadow of the ironing board
	for i in 4:
		var p := Polygon2D.new()
		p.show_behind_parent = true
		p.polygon = ell(Vector2(1010, 1020), 640 + i * 36, 56 + i * 12, 40)
		p.color = Color(0.12, 0.05, 0.12, 0.08)
		add_child(p)
	var board := Sprite2D.new()
	board.show_behind_parent = true
	board.texture = load("res://games/ironing/assets/board.png")
	board.centered = false
	board.position = BOARD_POS
	board.scale = Vector2(BOARD_SCALE, BOARD_SCALE)
	board.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(board)
	shade = Node2D.new()
	shade.show_behind_parent = true
	shade.draw.connect(_shade_draw)
	add_child(shade)
	layer = Node2D.new()
	layer.show_behind_parent = true
	var sh := Shader.new()
	sh.code = GARMENT_SHADER
	mat = ShaderMaterial.new()
	mat.shader = sh
	layer.material = mat
	layer.draw.connect(_layer_draw)
	add_child(layer)

	var dbg := {}
	for arg in OS.get_cmdline_user_args():
		dbg[arg.get_slice("=", 0)] = arg.get_slice("=", 1) if "=" in arg else "1"
	reset_game(dbg.get("--garment", "pink"))
	if dbg.has("--half"):
		for cy in rows:
			for cx in cols:
				if cx < cols * 0.55 and valid[cy * cols + cx] == 1:
					wr[cy * cols + cx] = 0.0
		mask_dirty = true
		started = true
		g_pop = 5.0
		pressing = true
	if dbg.has("--over"):
		ironed_count = 5
		end_game()
	if dbg.has("--rail"):
		for i in 4:
			var n: String = GARMENTS[(i + 1) % GARMENTS.size()]
			hung.append({"tex": load("res://games/ironing/assets/%s_after.png" % n), "slot": i, "age": 5.0})
		hung_total = 4
		started = true


# ---------------------------------------------------------------- helpers
func ell(c: Vector2, rx: float, ry: float, n: int = 32, rot: float = 0.0) -> PackedVector2Array:
	var o := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		o.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return o


func closed(p: PackedVector2Array) -> PackedVector2Array:
	var c := p.duplicate()
	c.append(p[0])
	return c


func panel(r: Rect2, col: Color, border: Color, bw: int, rad: int, shadow: int = 0) -> void:
	sb.bg_color = col
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(rad)
	sb.shadow_size = shadow
	sb.shadow_color = Color(0.05, 0.05, 0.2, 0.35)
	sb.shadow_offset = Vector2(0, 8)
	sb.anti_aliasing = true
	draw_style_box(sb, r)


func gloss_panel(r: Rect2, col: Color, border: Color, rad: int, shadow: int = 12) -> void:
	panel(r, col.darkened(0.12), border, 6, rad, shadow)
	panel(Rect2(r.position + Vector2(7, 7), r.size - Vector2(14, 14)), col, Color(0, 0, 0, 0), 0, rad - 6)
	panel(Rect2(r.position + Vector2(12, 10), Vector2(r.size.x - 24, r.size.y * 0.42)), Color(1, 1, 1, 0.30), Color(0, 0, 0, 0), 0, rad - 8)


func text_c(s: String, pos: Vector2, size: int, col: Color, ocol: Color, osize: int, center: bool = true) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := pos - Vector2(w / 2.0 if center else 0.0, 0)
	draw_string_outline(font, p + Vector2(0, 5), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, osize, Color(0, 0, 0, 0.22 * col.a))
	draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, osize, ocol)
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func star_pts(c: Vector2, r: float, rot: float = -PI / 2, inner: float = 0.52, n: int = 5) -> PackedVector2Array:
	var o := PackedVector2Array()
	for i in n * 2:
		var rr := r if i % 2 == 0 else r * inner
		o.append(c + Vector2.from_angle(rot + i * PI / n) * rr)
	return o


func draw_star(c: Vector2, r: float, rot: float = -PI / 2, dim_it: bool = false) -> void:
	var pts := star_pts(c, r, rot)
	var k := 0.45 if dim_it else 1.0
	draw_colored_polygon(star_pts(c + Vector2(0, r * 0.14), r * 1.05, rot), Color(0, 0, 0, 0.25))
	draw_polyline(closed(pts), Color(1, 0.58, 0.10).lerp(Color(0.4, 0.4, 0.45), 1.0 - k), r * 0.24, true)
	draw_colored_polygon(pts, Color(1, 0.84, 0.18).lerp(Color(0.55, 0.55, 0.6), 1.0 - k))
	draw_colored_polygon(star_pts(c + Vector2(-r * 0.05, -r * 0.08), r * 0.62, rot), Color(1, 0.95, 0.55).lerp(Color(0.7, 0.7, 0.75), 1.0 - k))


func fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out


func load_best() -> void:
	var cf := ConfigFile.new()
	if cf.load("user://ironing_best.cfg") == OK:
		best = int(cf.get_value("s", "best_count", 0))


func save_best() -> void:
	var cf := ConfigFile.new()
	cf.set_value("s", "best_count", best)
	cf.save("user://ironing_best.cfg")


# ---------------------------------------------------------------- sound (generated in code, no files needed)
const SR := 22050


func to_wav(buf: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = buf.size()
	return w


func tones(notes: Array, dur: float, gap: float, vol: float = 0.35) -> AudioStreamWAV:
	# bell-like arpeggio: notes played one after another
	var n := int((gap * notes.size() + dur) * SR)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for k in notes.size():
		var f: float = notes[k]
		var st := int(k * gap * SR)
		for i in int(dur * SR):
			var t := float(i) / SR
			var env := exp(-t * 7.0) * minf(t * 200.0, 1.0)
			var v := (sin(TAU * f * t) + 0.35 * sin(TAU * f * 2.0 * t) + 0.12 * sin(TAU * f * 3.0 * t)) * env * vol
			if st + i < n:
				buf[st + i] += v
	return to_wav(buf)


func setup_audio() -> void:
	# steam hiss: soft filtered-noise loop whose volume follows the ironing
	var buf := PackedFloat32Array()
	buf.resize(SR)
	var lp := 0.0
	for i in SR:
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.35)
		buf[i] = lp * 0.5
	snd_hiss = AudioStreamPlayer.new()
	snd_hiss.stream = to_wav(buf, true)
	snd_hiss.volume_db = -80.0
	add_child(snd_hiss)
	snd_hiss.play()
	wav_chime = tones([784.0, 988.0, 1175.0, 1568.0], 0.6, 0.09)
	wav_ding = tones([1046.0, 1318.0], 0.35, 0.07, 0.25)
	wav_tick = tones([1400.0], 0.07, 0.0, 0.3)
	wav_end = tones([1046.0, 880.0, 784.0, 1046.0, 1318.0], 0.7, 0.14)
	wav_pop = tones([660.0], 0.12, 0.0, 0.25)
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		snd_fx.append(p)


func play(w: AudioStreamWAV) -> void:
	for p in snd_fx:
		if not p.playing:
			p.stream = w
			p.play()
			return
	snd_fx[0].stream = w
	snd_fx[0].play()


# ---------------------------------------------------------------- game flow
func reset_game(first: String = "pink") -> void:
	score = 0.0
	disp_score = 0.0
	time_left = GAME_TIME
	last_tick = -1
	ironed_count = 0
	started = false
	state = "play"
	hung.clear()
	hung_total = 0
	flyers.clear()
	popups.clear()
	steam.clear()
	sparkles.clear()
	bag.clear()
	new_garment(first)


func new_garment(name: String = "") -> void:
	if name == "":
		if bag.is_empty():
			bag = GARMENTS.duplicate()
			bag.shuffle()
			if bag.back() == g_name:
				bag.reverse()
		name = bag.pop_back()
	g_name = name
	g_before = load("res://games/ironing/assets/%s_before.png" % name)
	g_after = load("res://games/ironing/assets/%s_after.png" % name)
	g_size = Vector2(g_before.get_size())
	var s := minf(GARMENT_LEN / g_size.y, 500.0 / (g_size.x * SQUASH))
	g_scale = Vector2(s * SQUASH, s)
	cols = int(ceil(g_size.x / CELL_SRC))
	rows = int(ceil(g_size.y / CELL_SRC))
	var ib := g_before.get_image()
	var ia := g_after.get_image()
	valid.resize(cols * rows)
	wr.resize(cols * rows)
	cell_scr.resize(cols * rows)
	valid_n = 0
	for cy in rows:
		for cx in cols:
			var idx := cy * cols + cx
			var px := Vector2(minf((cx + 0.5) * CELL_SRC, g_size.x - 1.0), minf((cy + 0.5) * CELL_SRC, g_size.y - 1.0))
			var ok := ib.get_pixelv(Vector2i(px)).a > 0.5 or ia.get_pixelv(Vector2i(px)).a > 0.5
			valid[idx] = 1 if ok else 0
			wr[idx] = 1.0 if ok else 0.0
			if ok:
				valid_n += 1
			var cl := Vector2((cx + 0.5) * CELL_SRC, (cy + 0.5) * CELL_SRC) - g_size / 2.0
			cell_scr[idx] = GARMENT_POS + Vector2(cl.x * g_scale.x, cl.y * g_scale.y).rotated(GARMENT_ROT)
	var first := true
	for idx in cols * rows:
		if valid[idx] == 1:
			if first:
				reach_rect = Rect2(cell_scr[idx], Vector2.ZERO)
				first = false
			else:
				reach_rect = reach_rect.expand(cell_scr[idx])
	reach_rect = reach_rect.grow(20.0)
	mask_img = Image.create(cols, rows, false, Image.FORMAT_R8)
	mask_tex = ImageTexture.create_from_image(mask_img)
	mat.set_shader_parameter("after_tex", g_after)
	mat.set_shader_parameter("mask_tex", mask_tex)
	mat.set_shader_parameter("mask_scale", Vector2(g_size.x / (cols * CELL_SRC), g_size.y / (rows * CELL_SRC)))
	mask_dirty = true
	progress = 0.0
	disp_progress = 0.0
	g_pop = 0.0
	said_half = false
	said_almost = false
	guide_cell = -1
	idle_t = 0.0


func complete_garment() -> void:
	Trial.resolve(true)
	ironed_count += 1
	score += 150.0
	score_pop = 1.0
	popups.append({"s": PRAISE[rng.randi() % PRAISE.size()], "p": Vector2(960, 430), "t": 0.0, "c": Color(1, 0.88, 0.25), "z": 110})
	play(wav_chime)
	# fly the finished garment to the rail
	var slot := hung_total % RAIL_SLOTS
	hung_total += 1
	hung = hung.filter(func(h): return h.slot != slot)
	flyers.append({"tex": g_after, "size": g_size, "from_scale": g_scale, "t": 0.0, "slot": slot})
	if fx_on:
		for i in 40:
			var p := GARMENT_POS + Vector2(rng.randf_range(-300, 300), rng.randf_range(-180, 180))
			add_sparkle(p, 1.5)
	new_garment()


func end_game() -> void:
	state = "over"
	pressing = false
	over_t = 0.0
	time_left = 0.0
	snd_hiss.volume_db = -80.0
	play(wav_end)
	if ironed_count > best:
		best = ironed_count
		save_best()


# ---------------------------------------------------------------- input
func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		target = GamePointer.local(self)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		target = GamePointer.local(self)
		if e.pressed:
			if not handle_click(target):
				pressing = state == "play" and not paused
		else:
			pressing = false
	elif e is InputEventKey and e.pressed and not e.echo and (e.keycode == KEY_ESCAPE or e.keycode == KEY_P):
		if state == "play":
			paused = not paused
			pressing = false


func handle_click(p: Vector2) -> bool:
	if paused:
		if b_resume.has_point(p):
			paused = false
		return true
	if state == "over":
		if over_t > 0.8 and b_again.has_point(p):
			reset_game()
		return true
	return false


# ---------------------------------------------------------------- simulation
func iron_at(p: Vector2, amount: float) -> float:
	var rx := IRON_RX
	var ry := IRON_RY
	var removed := 0.0
	for idx in cols * rows:
		if valid[idx] == 0 or wr[idx] <= 0.0:
			continue
		var c := cell_scr[idx]
		if absf(c.x - p.x) > rx + 40.0 or absf(c.y - p.y) > rx + 40.0:
			continue
		var d := (c - p).rotated(-IRON_ANG)
		var k := (d.x * d.x) / (rx * rx) + (d.y * d.y) / (ry * ry)
		if k < 1.0:
			var old := wr[idx]
			var nw := maxf(0.0, old - amount * (1.0 - k * 0.6))
			if old > 0.35 and nw <= 0.35 and fx_on and rng.randf() < 0.5:
				add_sparkle(c + Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10)))
			wr[idx] = nw
			removed += old - nw
	return removed


func add_sparkle(p: Vector2, big: float = 1.0) -> void:
	var l := rng.randf_range(0.5, 1.0)
	sparkles.append({"p": p, "life": l, "max": l, "s": rng.randf_range(10.0, 22.0) * big, "r": rng.randf() * PI})


func _process(dt: float) -> void:
	time += dt
	# Device: the assessed range covers the garment. Simulation: the mouse goes anywhere.
	target = reach_rect.position + GamePointer.normalized(self) * reach_rect.size if Trial.hardware else GamePointer.local(self)
	var goal := cell_scr[guide_cell] if guide_cell >= 0 and guide_cell < cell_scr.size() else GARMENT_POS
	Trial.advance(dt, paused, target / Vector2(1920, 1080), goal / Vector2(1920, 1080))
	if Trial.running and not Trial.target_open and not paused and state == "play":
		Trial.appear(GARMENT_POS / Vector2(1920, 1080))
	if Trial.held() or not Trial.running:
		snd_hiss.volume_db = -80.0
		queue_redraw()
		return
	var over_ui := false
	pass # The app keeps the mouse visible for its own Pause / Exit buttons.
	if paused:
		snd_hiss.volume_db = -80.0
		queue_redraw()
		return

	var prev := iron_pos
	iron_pos = iron_pos.lerp(target, 1.0 - exp(-16.0 * dt))
	iron_vel = iron_vel.lerp((iron_pos - prev) / maxf(dt, 0.0001), 1.0 - exp(-10.0 * dt))
	var dist := (iron_pos - prev).length()
	g_pop += dt

	if state == "play":
		# easy mode: the iron works just by moving it - no need to hold the button
		idle_t += dt
		var removed := 0.0
		if state == "play" and not over_ui:
			var steps := maxi(1, int(dist / 10.0))
			for i in steps:
				removed += iron_at(prev.lerp(iron_pos, float(i + 1) / steps), dist / steps * IRON_RATE)
			if removed > 0.0:
				mask_dirty = true
				started = true
				idle_t = 0.0
		var hiss := clampf(removed * 0.6, 0.0, 1.0)
		var cur := db_to_linear(snd_hiss.volume_db)
		snd_hiss.volume_db = linear_to_db(maxf(lerpf(cur, hiss * 0.5, 1.0 - exp(-10.0 * dt)), 0.0001))
		if removed > 0.0:
			if fx_on:
				var cnt := dist * 0.05 + 0.25
				while cnt > 0.0:
					if rng.randf() < cnt:
						var sp := iron_pos + Vector2(rng.randf_range(-110, 20), rng.randf_range(-14, 14))
						var l := rng.randf_range(0.9, 1.7)
						steam.append({"p": sp, "v": Vector2(rng.randf_range(-35, 25), rng.randf_range(-110, -50)), "s": rng.randf_range(14, 26), "life": l, "max": l})
					cnt -= 1.0
		var sum := 0.0
		for i in cols * rows:
			sum += wr[i]
		progress = 1.0 - sum / maxf(valid_n, 1)
		if state == "play" and progress >= 0.5 and not said_half:
			said_half = true
			popups.append({"s": "Keep going!", "p": Vector2(960, 330), "t": 0.0, "c": Color(0.6, 1.0, 0.55), "z": 72})
			play(wav_ding)
		if state == "play" and progress >= 0.75 and not said_almost:
			said_almost = true
			popups.append({"s": "Almost there!", "p": Vector2(960, 330), "t": 0.0, "c": Color(0.6, 0.9, 1.0), "z": 72})
			play(wav_ding)
		# guide: point at the remaining wrinkles when the player is stuck or nearly done
		guide_scan -= dt
		if state == "play" and guide_scan <= 0.0:
			guide_scan = 0.3
			guide_cell = find_wrinkle() if (idle_t > GUIDE_IDLE or progress > 0.75) else -1
		if state == "play" and progress >= DONE_AT:
			for i in cols * rows:
				wr[i] = 0.0
			mask_dirty = true
			upload_mask()
			complete_garment()
	else:
		over_t += dt
		if fx_on and rng.randf() < 0.3:
			add_sparkle(Vector2(rng.randf_range(560, 1360), rng.randf_range(250, 800)), 1.3)

	disp_progress = lerpf(disp_progress, progress, 1.0 - exp(-8.0 * dt))
	disp_score = lerpf(disp_score, score, 1.0 - exp(-6.0 * dt))
	score_pop = maxf(0.0, score_pop - dt * 4.0)
	if mask_dirty:
		upload_mask()

	for s in steam:
		s.life -= dt
		s.p += s.v * dt
		s.v *= 1.0 - dt * 0.6
		s.s += dt * 28.0
	steam = steam.filter(func(s): return s.life > 0.0)
	if steam.size() > 260:
		steam = steam.slice(steam.size() - 260)
	for s in sparkles:
		s.life -= dt
	sparkles = sparkles.filter(func(s): return s.life > 0.0)
	for pp in popups:
		pp.t += dt
	popups = popups.filter(func(pp): return pp.t < 1.3)
	for f in flyers:
		f.t += dt
		if f.t >= 0.9:
			hung.append({"tex": f.tex, "slot": f.slot, "age": 0.0})
	flyers = flyers.filter(func(f): return f.t < 0.9)
	for h in hung:
		h.age += dt
	queue_redraw()
	shade.queue_redraw()
	layer.queue_redraw()


func upload_mask() -> void:
	for cy in rows:
		for cx in cols:
			var idx := cy * cols + cx
			mask_img.set_pixel(cx, cy, Color(1.0 - wr[idx] if valid[idx] == 1 else 1.0, 0, 0))
	mask_tex.update(mask_img)
	mask_dirty = false


func find_wrinkle() -> int:
	# centre of the remaining wrinkles, snapped to the nearest still-wrinkled cell
	var c := Vector2.ZERO
	var n := 0
	for i in cols * rows:
		if valid[i] == 1 and wr[i] > 0.3:
			c += cell_scr[i]
			n += 1
	if n == 0:
		return -1
	c /= n
	var bi := -1
	var bd := INF
	for i in cols * rows:
		if valid[i] == 1 and wr[i] > 0.3:
			var d := cell_scr[i].distance_squared_to(c)
			if d < bd:
				bd = d
				bi = i
	return bi


# ---------------------------------------------------------------- drawing: behind layers
func pop_scale() -> float:
	var t := clampf(g_pop / 0.4, 0.0, 1.0)
	var c1 := 1.70158
	var e := 1.0 + (c1 + 1.0) * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)
	return lerpf(0.6, 1.0, e)


func _layer_draw() -> void:
	if g_before == null:
		return
	mat.set_shader_parameter("fade", clampf(g_pop / 0.2, 0.0, 1.0))
	var s := pop_scale()
	layer.draw_set_transform(GARMENT_POS, GARMENT_ROT, g_scale * s)
	layer.draw_texture_rect(g_before, Rect2(-g_size / 2.0, g_size), false)


func _shade_draw() -> void:
	if g_after == null:
		return
	var s := pop_scale()
	var a := clampf(g_pop / 0.2, 0.0, 1.0) * 0.22
	shade.draw_set_transform(GARMENT_POS + Vector2(10, 16), GARMENT_ROT, g_scale * s)
	shade.draw_texture_rect(g_after, Rect2(-g_size / 2.0, g_size), false, Color(0.1, 0.1, 0.3, a))


# ---------------------------------------------------------------- drawing: front
func _draw() -> void:
	draw_rail()
	draw_flyers()
	draw_effects(false)
	if state == "play":
		if not started:
			draw_hint(1.0)
		draw_iron()
		draw_guide()
	draw_effects(true)
	draw_popups()


func slot_x(slot: int) -> float:
	return 80.0 + slot * 125.0


func hang_scale(sz: Vector2) -> float:
	return minf(235.0 / sz.y, 120.0 / sz.x)


func draw_hanger(sz: Vector2, a: float) -> void:
	# local coords: garment centred at origin
	var top := -sz.y / 2.0
	var tip := sz.x * 0.46
	var wood := Color(0.80, 0.56, 0.32, a)
	draw_polyline(PackedVector2Array([Vector2(-tip, top + sz.y * 0.10), Vector2(0, top - 22), Vector2(tip, top + sz.y * 0.10)]), Color(0, 0, 0, 0.25 * a), 26)
	draw_polyline(PackedVector2Array([Vector2(-tip, top + sz.y * 0.09), Vector2(0, top - 24), Vector2(tip, top + sz.y * 0.09)]), wood, 22)
	draw_line(Vector2(0, top - 24), Vector2(0, top - 46), Color(0.78, 0.8, 0.9, a), 14)
	draw_arc(Vector2(0, top - 62), 22, PI * 0.5, PI * 2.0, 16, Color(0.78, 0.8, 0.9, a), 14, true)


func draw_hung_item(tex: Texture2D, center: Vector2, rot: float, sc: Vector2, hanger_a: float) -> void:
	var sz := Vector2(tex.get_size())
	draw_set_transform(center, rot, sc)
	if hanger_a > 0.0:
		draw_hanger(sz, hanger_a)
	draw_texture_rect(tex, Rect2(-sz / 2.0, sz), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_rail() -> void:
	var x0 := 30.0
	var x1 := slot_x(RAIL_SLOTS - 1) + 85.0
	draw_line(Vector2(x0 + 14, 0), Vector2(x0 + 14, RAIL_Y), Color(0.9, 0.9, 0.96, 0.9), 5)
	draw_line(Vector2(x1 - 14, 0), Vector2(x1 - 14, RAIL_Y), Color(0.9, 0.9, 0.96, 0.9), 5)
	draw_line(Vector2(x0, RAIL_Y + 6), Vector2(x1, RAIL_Y + 6), Color(0, 0, 0, 0.25), 16)
	draw_line(Vector2(x0, RAIL_Y), Vector2(x1, RAIL_Y), Color(0.55, 0.62, 0.78), 14)
	draw_line(Vector2(x0, RAIL_Y - 3), Vector2(x1, RAIL_Y - 3), Color(0.92, 0.95, 1.0), 4)
	draw_circle(Vector2(x0, RAIL_Y), 13, Color(0.45, 0.5, 0.68))
	draw_circle(Vector2(x1, RAIL_Y), 13, Color(0.45, 0.5, 0.68))
	for h in hung:
		var tex: Texture2D = h.tex
		var sz := Vector2(tex.get_size())
		var hs := hang_scale(sz)
		var sw := exp(-h.age * 2.2) * sin(h.age * 9.0) * 0.14 + sin(time * 1.6 + h.slot) * 0.025
		var pivot := Vector2(slot_x(h.slot), RAIL_Y)
		var off := Vector2(0, (sz.y / 2.0 + 62.0) * hs).rotated(sw)
		draw_hung_item(tex, pivot + off, sw, Vector2(hs, hs), 1.0)


func draw_flyers() -> void:
	for f in flyers:
		var t: float = clampf(f.t / 0.9, 0.0, 1.0)
		var e := t * t * (3.0 - 2.0 * t)
		var tex: Texture2D = f.tex
		var sz: Vector2 = f.size
		var hs := hang_scale(sz)
		var end := Vector2(slot_x(f.slot), RAIL_Y + (sz.y / 2.0 + 62.0) * hs)
		var pos := GARMENT_POS.lerp(end, e) + Vector2(0, -sin(t * PI) * 140.0)
		var sc: Vector2 = (f.from_scale as Vector2).lerp(Vector2(hs, hs), e)
		draw_hung_item(tex, pos, lerpf(GARMENT_ROT, 0.0, e), sc, e * e)


func draw_effects(front: bool) -> void:
	if not front:
		for s in steam:
			var a: float = s.life / s.max
			draw_circle(s.p, s.s, Color(1, 1, 1, 0.10 * a))
			draw_circle(s.p, s.s * 0.65, Color(1, 1, 1, 0.14 * a))
	else:
		for s in sparkles:
			var a: float = s.life / s.max
			var sz: float = s.s * (0.4 + 0.6 * sin(a * PI))
			var rot: float = s.r + time * 2.0
			draw_circle(s.p, sz * 0.9, Color(1, 0.9, 0.4, 0.18 * a))
			draw_colored_polygon(star_pts(s.p, sz, rot, 0.2, 4), Color(1, 0.95, 0.6, a))
			draw_colored_polygon(star_pts(s.p, sz * 0.5, rot, 0.3, 4), Color(1, 1, 1, a))
		for s in steam:
			var a: float = s.life / s.max
			if s.s > 30.0:
				draw_circle(s.p + Vector2(10, -6), s.s * 0.8, Color(1, 1, 1, 0.07 * a))


func draw_iron() -> void:
	var lift := 0.0 if (state == "play" and not b_pause.has_point(target)) else 26.0 + sin(time * 3.0) * 4.0
	var tilt := clampf(iron_vel.x * 0.00005, -0.05, 0.05)
	var ground := iron_pos + Vector2(14, 24)
	for i in 5:
		var k := float(i) / 4.0
		draw_colored_polygon(ell(ground, 160 + lift * 0.5 + k * 24, 35 + lift * 0.2 + k * 10, 40, IRON_ANG), Color(0.12, 0.05, 0.2, 0.08))
	var sz := Vector2(tex_iron.get_size())
	draw_set_transform(iron_pos + Vector2(0, -lift), tilt, Vector2(IRON_SCALE, IRON_SCALE))
	draw_texture_rect(tex_iron, Rect2(-IRON_ANCHOR, sz), false)
	var sp := 0.5 + 0.5 * sin(time * 4.0)
	draw_colored_polygon(star_pts(Vector2(150, -20) - IRON_ANCHOR + IRON_ANCHOR, 20 + 10 * sp, 0.0, 0.18, 4), Color(1, 1, 1, 0.9))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_hint(alpha: float) -> void:
	var a := clampf(alpha, 0.0, 1.0)
	var A := Vector2(760, 800)
	var C := Vector2(990, 700)
	var B := Vector2(1260, 790)
	var pts := PackedVector2Array()
	for i in 41:
		var t := float(i) / 40.0
		pts.append(A.lerp(C, t).lerp(C.lerp(B, t), t))
	for i in range(0, 40, 3):
		if i % 6 < 3:
			var j := mini(i + 2, 40)
			draw_line(pts[i] + Vector2(3, 5), pts[j] + Vector2(3, 5), Color(0, 0, 0, 0.25 * a), 16)
			draw_line(pts[i], pts[j], Color(1, 1, 1, a), 14)
	var dir := (pts[40] - pts[37]).normalized()
	var n := dir.orthogonal()
	draw_colored_polygon(PackedVector2Array([pts[40] + dir * 26, pts[40] + n * 26, pts[40] - n * 26]), Color(1, 1, 1, a))
	var u := fmod(time * 0.5, 1.5)
	var k := clampf(u / 1.1, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var hp := A.lerp(C, k).lerp(C.lerp(B, k), k)
	var ha := a * clampf(minf(k * 6.0, (1.0 - k) * 6.0), 0.0, 1.0)
	var ring := 30.0 + 8.0 * sin(time * 6.0)
	draw_arc(hp, ring, 0, TAU, 32, Color(1, 0.85, 0.85, 0.8 * ha), 6, true)
	draw_circle(hp, ring - 4, Color(1, 0.8, 0.82, 0.35 * ha))
	var skin := Color(0.99, 0.88, 0.85, ha)
	var out := Color(0.55, 0.36, 0.38, ha)
	for pass_i in 2:
		var col := out if pass_i == 0 else skin
		var g := 5.0 if pass_i == 0 else 0.0
		draw_line(hp + Vector2(0, 8), hp + Vector2(0, 50), col, 24 + g * 2)
		draw_circle(hp + Vector2(0, 8), 12 + g, col)
		draw_circle(hp + Vector2(6, 78), 38 + g, col)
		draw_circle(hp + Vector2(-20, 58), 13 + g, col)
		draw_circle(hp + Vector2(-4, 56), 13 + g, col)
		draw_circle(hp + Vector2(12, 56), 13 + g, col)


func draw_guide() -> void:
	if guide_cell < 0 or guide_cell >= cell_scr.size() or state != "play":
		return
	var p := cell_scr[guide_cell]
	var r := 70.0 + 14.0 * sin(time * 6.0)
	draw_arc(p, r + 6, 0, TAU, 48, Color(0, 0, 0, 0.25), 10, true)
	draw_arc(p, r, 0, TAU, 48, Color(1, 0.95, 0.4, 0.95), 10, true)
	draw_circle(p, r - 8, Color(1, 0.95, 0.5, 0.18))
	# bouncing arrow above the ring
	var tip := Vector2(p.x, p.y - r - 8 - absf(sin(time * 5.0)) * 28.0)
	var arrow := PackedVector2Array([tip, tip + Vector2(34, -40), tip + Vector2(14, -40), tip + Vector2(14, -90), tip + Vector2(-14, -90), tip + Vector2(-14, -40), tip + Vector2(-34, -40)])
	draw_colored_polygon(PackedVector2Array(Array(arrow).map(func(q): return q + Vector2(4, 6))), Color(0, 0, 0, 0.25))
	draw_colored_polygon(arrow, Color(1, 0.55, 0.2))
	draw_polyline(closed(arrow), Color.WHITE, 5, true)


func draw_popups() -> void:
	for p in popups:
		var t: float = p.t / 1.3
		var c: Color = p.c
		c.a = 1.0 - smoothstep(0.55, 1.0, t)
		var sc := 0.7 + 0.5 * (1.0 - pow(1.0 - minf(t * 4.0, 1.0), 3.0))
		draw_set_transform(p.p + Vector2(0, -t * 70.0), 0.0, Vector2(sc, sc))
		text_c(p.s, Vector2.ZERO, p.z, c, Color(0.45, 0.2, 0.05, c.a), 16)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_ui() -> void:
	# --- ironed count (small card)
	var pr := Rect2(50, 56, 250, 112)
	gloss_panel(pr, Color(0.38, 0.72, 0.98), Color(0.82, 0.94, 1.0), 34, 12)
	text_c("Ironed", Vector2(pr.position.x + 125, 98), 36, Color.WHITE, Color(0.12, 0.45, 0.85), 9)
	var sc := 1.0 + score_pop * 0.12
	draw_set_transform(Vector2(pr.position.x + 125, 152), 0.0, Vector2(sc, sc))
	text_c(str(ironed_count), Vector2(0, 0), 64, Color(1.0, 0.82, 0.16), Color(0.72, 0.36, 0.06), 12)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# --- progress
	var bar := Rect2(625, 64, 585, 86)
	panel(bar, Color(0.80, 0.93, 1.0), Color(0.58, 0.80, 0.95), 5, 43, 10)
	var track := Rect2(bar.position + Vector2(9, 9), bar.size - Vector2(18, 18))
	panel(track, Color(0.26, 0.38, 0.62), Color(0.18, 0.28, 0.5), 3, 34)
	var fw := maxf(track.size.y, track.size.x * clampf(disp_progress, 0.0, 1.0))
	if disp_progress > 0.003:
		var fr := Rect2(track.position, Vector2(fw, track.size.y))
		panel(fr, Color(0.28, 0.80, 0.18), Color(0.16, 0.6, 0.12), 2, 34)
		panel(Rect2(fr.position + Vector2(8, 6), Vector2(fr.size.x - 16, fr.size.y * 0.38)), Color(0.8, 1.0, 0.55, 0.65), Color(0, 0, 0, 0), 0, 14)
	text_c(str(int(round(disp_progress * 100.0))) + "%", Vector2(bar.position.x + bar.size.x / 2.0, bar.position.y + 62), 54, Color.WHITE, Color(0.12, 0.2, 0.4), 12)
	var pulse := 1.0 + 0.06 * sin(time * 4.0)
	draw_star(Vector2(bar.end.x + 25, bar.position.y + 43), 58.0 * pulse, -PI / 2 + 0.12)

	# --- 60 s timer
	var tc := Vector2(1560, 120)
	var frac := clampf(time_left / GAME_TIME, 0.0, 1.0)
	var low := time_left < 10.0 and started
	var tp := 1.0 + (0.07 * sin(time * 10.0) if low else 0.0)
	var ring := Color(0.35, 0.85, 0.30).lerp(Color(1.0, 0.82, 0.15), clampf((0.6 - frac) * 3.0, 0.0, 1.0)).lerp(Color(1.0, 0.30, 0.30), clampf((0.25 - frac) * 5.0, 0.0, 1.0))
	draw_circle(tc + Vector2(0, 8), 82 * tp, Color(0.05, 0.05, 0.2, 0.30))
	draw_circle(tc, 82 * tp, Color(0.82, 0.93, 1.0))
	draw_circle(tc, 73 * tp, Color(0.26, 0.38, 0.62))
	draw_arc(tc, 60 * tp, -PI / 2, -PI / 2 + TAU * frac, 64, ring, 15, true)
	var secs := int(ceil(time_left))
	text_c("%d:%02d" % [secs / 60, secs % 60], tc + Vector2(0, 17 * tp), int(46 * tp), Color.WHITE, Color(0.12, 0.2, 0.4), 10)
	# big centre countdown for the last 5 seconds
	if started and state == "play" and secs <= 5 and secs >= 1:
		var fr2 := fmod(time_left, 1.0)
		var big := 1.0 + 0.4 * fr2
		draw_set_transform(Vector2(960, 300), 0.0, Vector2(big, big))
		text_c(str(secs), Vector2(0, 50), 150, Color(1, 0.4, 0.35, 0.35 + 0.65 * fr2), Color(1, 1, 1, 0.35 + 0.65 * fr2), 16)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# --- buttons
	var hov_p := b_pause.has_point(target)
	var rp := b_pause.grow(4.0 if hov_p else 0.0)
	gloss_panel(rp, Color(0.96, 0.32, 0.46), Color(1.0, 0.85, 0.88), 40, 10)
	var pc := rp.get_center()
	panel(Rect2(pc + Vector2(-26, -34), Vector2(20, 68)), Color.WHITE, Color(0, 0, 0, 0), 0, 8, 4)
	panel(Rect2(pc + Vector2(6, -34), Vector2(20, 68)), Color.WHITE, Color(0, 0, 0, 0), 0, 8, 4)


func button(r: Rect2, label: String, col: Color) -> void:
	var rr := r.grow(5.0 if r.has_point(target) else 0.0)
	gloss_panel(rr, col, col.lightened(0.6), 44, 12)
	text_c(label, rr.get_center() + Vector2(0, 22), 60, Color.WHITE, col.darkened(0.45), 12)


func dim(a: float) -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.05, 0.08, 0.2, a))


func draw_over() -> void:
	var t := clampf(over_t / 0.5, 0.0, 1.0)
	dim(0.55 * t)
	var e := 1.0 - pow(1.0 - t, 3.0)
	draw_set_transform(Vector2(960, 540), 0.0, Vector2(e, e))
	gloss_panel(Rect2(-400, -330, 800, 640), Color(0.42, 0.74, 0.98), Color(0.85, 0.95, 1.0), 70, 24)
	text_c("TIME'S UP!", Vector2(0, -190), 112, Color(1.0, 0.88, 0.25), Color(0.65, 0.3, 0.05), 22)
	var stars := 1 + (1 if ironed_count >= 3 else 0) + (1 if ironed_count >= 6 else 0)
	for i in 3:
		var d := clampf((over_t - 0.4 - i * 0.25) / 0.35, 0.0, 1.0)
		var s := (1.0 + 0.5 * (1.0 - d)) * d
		draw_star(Vector2(-130 + i * 130, -75 - (28 if i == 1 else 0)), 58.0 * s, -PI / 2, i >= stars)
	text_c(str(ironed_count), Vector2(0, 85), 110, Color(1.0, 0.82, 0.16), Color(0.72, 0.36, 0.06), 20)
	text_c("Garments ironed     Best: %d" % best, Vector2(0, 160), 40, Color.WHITE, Color(0.12, 0.4, 0.8), 10)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if over_t > 0.8:
		button(b_again, "PLAY AGAIN", Color(0.30, 0.78, 0.25))


func draw_pause() -> void:
	dim(0.55)
	gloss_panel(Rect2(610, 250, 700, 520), Color(0.42, 0.74, 0.98), Color(0.85, 0.95, 1.0), 70, 24)
	text_c("PAUSED", Vector2(960, 440), 120, Color.WHITE, Color(0.12, 0.4, 0.8), 22)
	button(b_resume, "RESUME", Color(0.30, 0.78, 0.25))
