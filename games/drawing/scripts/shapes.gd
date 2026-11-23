class_name Shapes
extends RefCounted
## Procedural textures so the project needs no external art files.

static func circle(px: int, shade: float = 0.14) -> ImageTexture:
	## White anti-aliased disc with a soft top-left highlight (tinted later via modulate).
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := Vector2(px, px) * 0.5
	var r := px * 0.5 - 1.0
	for y in px:
		for x in px:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(c)
			var a := clampf(r - d, 0.0, 1.0)
			var lit := 1.0 - shade * clampf((p.x + p.y - px * 0.6) / px, 0.0, 1.0)
			img.set_pixel(x, y, Color(lit, lit, lit, a))
	return ImageTexture.create_from_image(img)

static func ring(px: int, thickness: float) -> ImageTexture:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := Vector2(px, px) * 0.5
	var r := px * 0.5 - 1.0
	for y in px:
		for x in px:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var a := clampf(r - d, 0.0, 1.0) * clampf(d - (r - thickness), 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

static func star(px: int) -> ImageTexture:
	var pts := PackedVector2Array()
	var c := Vector2(px, px) * 0.5
	for i in 10:
		var rad := (px * 0.48) if i % 2 == 0 else (px * 0.2)
		pts.append(c + Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * rad)
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	for y in px:
		for x in px:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)
