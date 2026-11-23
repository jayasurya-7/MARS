class_name BedroomRoom
extends LivingRoom
## Bedroom: double bed, nightstands with lamps, wardrobe, dresser with mirror, plant.


func _build() -> void:
	var hx := room.x * 0.5
	var hz := room.y * 0.5
	_baseboards(hx, hz)

	var wood := _mat(Color(0.5, 0.33, 0.2), 0.45)
	var light_wood := _mat(Color(0.72, 0.56, 0.38), 0.45)
	var linen := _mat(Color(0.95, 0.94, 0.92), 0.95)
	var duvet := _mat(Color(0.42, 0.52, 0.66), 0.95)
	var fold := _mat(Color(0.82, 0.86, 0.92), 0.95)

	# --- bed (head against the back wall)
	var bed := _root(Vector3(-1.0, 0.0, -hz + 1.05))
	_box(bed, Vector3(1.7, 0.3, 2.1), Vector3(0, 0.2, 0), wood)
	_box(bed, Vector3(1.6, 0.22, 2.0), Vector3(0, 0.45, 0.02), linen)
	_box(bed, Vector3(1.64, 0.12, 1.45), Vector3(0, 0.58, 0.28), duvet)
	_box(bed, Vector3(1.64, 0.06, 0.3), Vector3(0, 0.62, -0.38), fold)
	_box(bed, Vector3(1.74, 0.9, 0.08), Vector3(0, 0.6, -1.04), wood)
	for x in [-0.4, 0.4]:
		_box(bed, Vector3(0.62, 0.14, 0.4), Vector3(x, 0.62, -0.78), linen, Vector3(-8, 0, 0))
	_obstacle(Vector2(-1.0, -hz + 1.05), Vector2(1.7, 2.1))

	# --- nightstands with lamps
	for x in [-2.3, 0.3]:
		var n := _root(Vector3(x, 0.0, -hz + 0.25))
		_box(n, Vector3(0.45, 0.5, 0.4), Vector3(0, 0.25, 0), light_wood)
		_box(n, Vector3(0.38, 0.015, 0.01), Vector3(0, 0.3, 0.2), wood)
		_box(n, Vector3(0.38, 0.015, 0.01), Vector3(0, 0.15, 0.2), wood)
		_cyl(n, 0.03, 0.045, 0.2, Vector3(0, 0.6, 0), _mat(Color(0.9, 0.9, 0.88), 0.2))
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color(1.0, 0.92, 0.75)
		glow.emission_enabled = true
		glow.emission = Color(1.0, 0.85, 0.55)
		glow.emission_energy_multiplier = 1.4
		_cyl(n, 0.07, 0.11, 0.17, Vector3(0, 0.78, 0), glow)
		_obstacle(Vector2(x, -hz + 0.25), Vector2(0.45, 0.4))

	# --- wardrobe on the right wall
	var w := _root(Vector3(hx - 0.3, 0.0, -0.9))
	_box(w, Vector3(0.6, 2.0, 1.6), Vector3(0, 1.0, 0), light_wood)
	_box(w, Vector3(0.012, 1.9, 0.012), Vector3(-0.31, 1.0, 0), wood)
	_box(w, Vector3(0.025, 0.25, 0.03), Vector3(-0.31, 1.0, -0.06), _mat(Color(0.8, 0.8, 0.8), 0.3, 0.9))
	_box(w, Vector3(0.025, 0.25, 0.03), Vector3(-0.31, 1.0, 0.06), _mat(Color(0.8, 0.8, 0.8), 0.3, 0.9))
	_obstacle(Vector2(hx - 0.3, -0.9), Vector2(0.6, 1.6))
	# a pair of slippers on the floor
	var slip := _mat(Color(0.85, 0.55, 0.6), 0.9)
	_box(self, Vector3(0.1, 0.05, 0.24), Vector3(hx - 0.95, 0.025, 0.1), slip, Vector3(0, 12, 0))
	_box(self, Vector3(0.1, 0.05, 0.24), Vector3(hx - 0.8, 0.025, 0.15), slip, Vector3(0, -8, 0))

	# --- dresser with mirror on the left wall
	var d := _root(Vector3(-hx + 0.27, 0.0, 0.9), 0.0)
	_box(d, Vector3(0.5, 0.8, 1.2), Vector3(0, 0.4, 0), wood)
	for y in [0.2, 0.4, 0.6]:
		_box(d, Vector3(0.01, 0.01, 1.1), Vector3(0.255, y, 0), light_wood)
		_box(d, Vector3(0.02, 0.03, 0.15), Vector3(0.265, y - 0.06, 0), _mat(Color(0.8, 0.8, 0.8), 0.3, 0.9))
	_box(d, Vector3(0.03, 0.9, 0.7), Vector3(-0.2, 1.35, 0), _mat(Color(0.75, 0.8, 0.85), 0.04, 0.95))
	_box(d, Vector3(0.025, 0.96, 0.76), Vector3(-0.21, 1.35, 0), wood)
	# perfume bottles + photo frame
	_cyl(d, 0.03, 0.03, 0.12, Vector3(0.05, 0.86, -0.3), _mat(Color(0.6, 0.8, 0.9), 0.1))
	_cyl(d, 0.025, 0.025, 0.1, Vector3(0.05, 0.85, -0.2), _mat(Color(0.9, 0.6, 0.7), 0.1))
	_box(d, Vector3(0.02, 0.2, 0.15), Vector3(0.0, 0.9, 0.3), wood, Vector3(0, 0, -8))
	_obstacle(Vector2(-hx + 0.27, 0.9), Vector2(0.5, 1.2))

	# --- plant in the corner
	var p := _root(Vector3(-hx + 0.35, 0.0, -hz + 0.35))
	_cyl(p, 0.2, 0.15, 0.35, Vector3(0, 0.175, 0), _mat(Color(0.82, 0.8, 0.76), 0.7))
	var leaf := _mat(Color(0.2, 0.5, 0.22), 0.7)
	for i in 8:
		var a := float(i) / 8.0 * TAU
		_sphere(p, 0.13, Vector3(cos(a) * 0.14, 0.65 + (i % 3) * 0.2, sin(a) * 0.14), leaf,
			Vector3(0.8, 1.7, 0.8))
	_obstacle(Vector2(-hx + 0.35, -hz + 0.35), Vector2(0.45, 0.45))

	# --- window above the nightstand side
	_window(Vector3(2.0, 1.55, -hz), 0.0, Vector2(1.4, 1.3))
