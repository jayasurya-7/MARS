class_name Sprites
extends RefCounted
## Loads the vegetable and prop pictures from assets/. A missing file returns null, so
## callers can fall back to a simple drawn shape and the game never fails over art.

static var _cache := {}


static func veg(sprite_name: String) -> Texture2D:
	return _fetch("res://games/cooking/assets/veg/%s.png" % sprite_name)


static func prop(sprite_name: String) -> Texture2D:
	return _fetch("res://games/cooking/assets/props/%s.png" % sprite_name)


static func _fetch(path: String) -> Texture2D:
	if not _cache.has(path):
		_cache[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _cache[path]


## Draws a texture centred on a point, scaled to fit inside `size` pixels square.
static func draw_fit(ci: CanvasItem, tex: Texture2D, centre: Vector2, size: float,
		modulate: Color = Color.WHITE) -> void:
	var longest := float(maxi(tex.get_width(), tex.get_height()))
	var scale := size / longest
	var extent := Vector2(tex.get_width(), tex.get_height()) * scale
	ci.draw_texture_rect(tex, Rect2(centre - extent * 0.5, extent), false, modulate)


## As draw_fit, but anchored at the bottom centre, for things that stand on a surface.
static func draw_standing(ci: CanvasItem, tex: Texture2D, base: Vector2, size: float,
		modulate: Color = Color.WHITE) -> void:
	var longest := float(maxi(tex.get_width(), tex.get_height()))
	var scale := size / longest
	var extent := Vector2(tex.get_width(), tex.get_height()) * scale
	ci.draw_texture_rect(tex, Rect2(base - Vector2(extent.x * 0.5, extent.y), extent), false, modulate)
