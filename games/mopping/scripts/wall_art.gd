class_name WallArt
extends RefCounted
## Procedurally painted pictures for the walls. No image assets needed.

const KINDS := 6
const KIND_NAMES := ["Landscape", "Abstract circles", "Geometric blocks",
	"Sunset sea", "Mountains", "Polka dots"]


static func make(kind: int, seed_value: int, w := 192, h := 144) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	match kind % KINDS:
		0: _landscape(img, rng)
		1: _abstract(img, rng)
		2: _blocks(img, rng)
		3: _sunset(img)
		4: _mountains(img, rng)
		5: _dots(img, rng)
	return ImageTexture.create_from_image(img)


static func _circle(img: Image, cx: float, cy: float, r: float, col: Color) -> void:
	var x0 := maxi(int(cx - r), 0)
	var x1 := mini(int(cx + r) + 1, img.get_width())
	var y0 := maxi(int(cy - r), 0)
	var y1 := mini(int(cy + r) + 1, img.get_height())
	for y in range(y0, y1):
		for x in range(x0, x1):
			if Vector2(x - cx, y - cy).length() <= r:
				img.set_pixel(x, y, col)


static func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for yy in range(maxi(y, 0), mini(y + h, img.get_height())):
		for xx in range(maxi(x, 0), mini(x + w, img.get_width())):
			img.set_pixel(xx, yy, col)


static func _vgradient(img: Image, y0: int, y1: int, a: Color, b: Color) -> void:
	for y in range(y0, y1):
		var c := a.lerp(b, float(y - y0) / maxf(float(y1 - y0 - 1), 1.0))
		for x in img.get_width():
			img.set_pixel(x, y, c)


static func _landscape(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_vgradient(img, 0, h, Color(0.35, 0.62, 0.92), Color(0.9, 0.95, 1.0))
	_circle(img, w * 0.75, h * 0.26, h * 0.09, Color(1.0, 0.92, 0.45))
	var ph := rng.randf() * 6.0
	for x in w:
		var y1 := int(h * (0.62 + 0.07 * sin(x * 0.03 + ph)))
		var y2 := int(h * (0.74 + 0.05 * sin(x * 0.05 + ph * 2.0)))
		for y in range(y1, h):
			img.set_pixel(x, y, Color(0.35, 0.65, 0.35))
		for y in range(y2, h):
			img.set_pixel(x, y, Color(0.2, 0.5, 0.25))


static func _abstract(img: Image, rng: RandomNumberGenerator) -> void:
	img.fill(Color(0.96, 0.93, 0.86))
	var palette := [Color(0.9, 0.35, 0.3), Color(0.15, 0.4, 0.65), Color(0.95, 0.75, 0.2),
		Color(0.2, 0.6, 0.55), Color(0.35, 0.3, 0.5)]
	for _i in 9:
		_circle(img, rng.randf() * img.get_width(), rng.randf() * img.get_height(),
			rng.randf_range(10.0, 38.0), palette[rng.randi() % palette.size()])
	for _i in 3:
		_rect(img, rng.randi() % img.get_width(), 0, 3, img.get_height(), Color(0.12, 0.12, 0.15))


static func _blocks(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	img.fill(Color(0.97, 0.97, 0.94))
	var xs := [0, int(w * 0.3), int(w * 0.68), w]
	var ys := [0, int(h * 0.4), int(h * 0.76), h]
	var cols := [Color(0.85, 0.15, 0.12), Color(0.1, 0.25, 0.7), Color(0.98, 0.8, 0.1),
		Color(0.97, 0.97, 0.94), Color(0.97, 0.97, 0.94)]
	for i in 3:
		for j in 3:
			_rect(img, xs[i], ys[j], xs[i + 1] - xs[i], ys[j + 1] - ys[j],
				cols[rng.randi() % cols.size()])
	for i in range(1, 3):
		_rect(img, xs[i] - 2, 0, 4, h, Color(0.08, 0.08, 0.08))
		_rect(img, 0, ys[i] - 2, w, 4, Color(0.08, 0.08, 0.08))


static func _sunset(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var horizon := int(h * 0.6)
	_vgradient(img, 0, horizon, Color(0.35, 0.2, 0.5), Color(1.0, 0.6, 0.3))
	_circle(img, w * 0.5, horizon - 2, h * 0.17, Color(1.0, 0.85, 0.5))
	_vgradient(img, horizon, h, Color(0.95, 0.55, 0.35), Color(0.08, 0.15, 0.35))
	for y in range(horizon + 4, h, 7):          # glittering sea lines
		var half := int(w * 0.18 * (1.0 - float(y - horizon) / float(h - horizon)) + 6)
		_rect(img, w / 2 - half, y, half * 2, 2, Color(1.0, 0.8, 0.5))


static func _mountains(img: Image, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_vgradient(img, 0, h, Color(0.8, 0.88, 0.96), Color(0.97, 0.97, 1.0))
	for layer in 3:
		var shade := 0.45 + layer * 0.18
		var base := Color(0.3 * shade, 0.38 * shade, 0.55 * shade)
		for _p in 3:
			var cx := rng.randf() * w
			var ph := h * rng.randf_range(0.3, 0.6)
			var half := rng.randf_range(35.0, 70.0)
			for x in range(maxi(int(cx - half), 0), mini(int(cx + half), w)):
				var top := int(h - ph * (1.0 - absf(x - cx) / half) - layer * 12.0)
				for y in range(maxi(top, 0), h):
					var snow := layer == 0 and y < top + int(ph * 0.18)
					img.set_pixel(x, y, Color(0.97, 0.97, 1.0) if snow else base)


static func _dots(img: Image, rng: RandomNumberGenerator) -> void:
	var bg := Color(0.18, 0.55, 0.55)
	img.fill(bg)
	var dot := Color(0.98, 0.9, 0.7)
	var off := rng.randf() * 10.0
	for gy in range(0, img.get_height() + 24, 24):
		for gx in range(0, img.get_width() + 24, 24):
			var shift := 12.0 if (gy / 24) % 2 == 1 else 0.0
			_circle(img, gx + shift + off, gy, 7.0, dot)
