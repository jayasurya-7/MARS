class_name KitchenRoom
extends LivingRoom
## Kitchen: counter run with stove and sink, fridge, dining table with chairs, bin.


func _build() -> void:
	var hx := room.x * 0.5
	var hz := room.y * 0.5
	_baseboards(hx, hz)

	var cab := _mat(Color(0.94, 0.94, 0.92), 0.45)
	var top := _mat(Color(0.8, 0.58, 0.36), 0.4)
	var steel := _mat(Color(0.78, 0.8, 0.83), 0.25, 0.9)
	var dark := _mat(Color(0.07, 0.07, 0.08), 0.25)
	var line := _mat(Color(0.7, 0.7, 0.68), 0.6)

	# --- back counter run (x from -hx to 2.1)
	var run_len := 5.6
	var cx := -hx + run_len * 0.5
	var cz := -hz + 0.325
	_box(self, Vector3(run_len, 0.86, 0.65), Vector3(cx, 0.43, cz), cab)
	_box(self, Vector3(run_len + 0.02, 0.04, 0.68), Vector3(cx, 0.88, cz + 0.015), top)
	for i in 13:
		var x := -hx + 0.1 + i * (run_len - 0.2) / 12.0
		_box(self, Vector3(0.012, 0.7, 0.01), Vector3(x, 0.45, cz + 0.33), line)
		if i % 2 == 0 and i < 12:
			_box(self, Vector3(0.1, 0.014, 0.02), Vector3(x + 0.22, 0.72, cz + 0.34), steel)
	_obstacle(Vector2(cx, cz), Vector2(run_len, 0.65))

	# stove (dark glass top, burners, oven door) at x = -0.4
	_box(self, Vector3(0.62, 0.012, 0.5), Vector3(-0.4, 0.912, cz), dark)
	for p in [[-0.15, -0.12], [0.15, -0.12], [-0.15, 0.12], [0.15, 0.12]]:
		var b := _cyl(self, 0.07, 0.07, 0.008, Vector3(-0.4 + p[0], 0.92, cz + p[1] * 0.9), steel)
		b.scale = Vector3(1, 1, 1)
	_box(self, Vector3(0.6, 0.42, 0.02), Vector3(-0.4, 0.4, cz + 0.33), dark)
	_box(self, Vector3(0.5, 0.02, 0.02), Vector3(-0.4, 0.62, cz + 0.35), steel)
	# range hood
	var hood := _cyl(self, 0.2, 0.35, 0.3, Vector3(-0.4, 1.95, -hz + 0.35), steel)
	hood.scale = Vector3(1.4, 1.0, 0.8)

	# sink at x = -2.0
	_box(self, Vector3(0.7, 0.02, 0.45), Vector3(-2.0, 0.905, cz), steel)
	_box(self, Vector3(0.6, 0.012, 0.35), Vector3(-2.0, 0.915, cz), _mat(Color(0.5, 0.52, 0.55), 0.2, 0.9))
	_cyl(self, 0.014, 0.014, 0.28, Vector3(-2.0, 1.04, cz - 0.2), steel)
	var spout := _box(self, Vector3(0.02, 0.02, 0.16), Vector3(-2.0, 1.17, cz - 0.12), steel)
	spout.rotation_degrees.x = 0

	# upper cabinets (leave the window and hood clear)
	for x: float in [-3.0, -1.0, 1.1, 1.7]:
		var w: float = 1.0 if x < 0.0 else 0.55
		_box(self, Vector3(w, 0.7, 0.34), Vector3(x, 1.75, -hz + 0.17), cab)
		_box(self, Vector3(0.012, 0.64, 0.01), Vector3(x, 1.75, -hz + 0.345), line)

	# fridge in the back-right corner
	var fx := hx - 0.55
	var fz := -hz + 0.42
	_box(self, Vector3(0.8, 1.8, 0.75), Vector3(fx, 0.9, fz), _mat(Color(0.86, 0.87, 0.89), 0.3, 0.6))
	_box(self, Vector3(0.78, 0.012, 0.01), Vector3(fx, 1.2, fz + 0.38), dark)
	_box(self, Vector3(0.025, 0.4, 0.03), Vector3(fx - 0.3, 1.45, fz + 0.4), steel)
	_box(self, Vector3(0.025, 0.55, 0.03), Vector3(fx - 0.3, 0.7, fz + 0.4), steel)
	_obstacle(Vector2(fx, fz), Vector2(0.8, 0.75))

	# right-wall counter
	var rz := -0.55
	_box(self, Vector3(0.65, 0.86, 2.2), Vector3(hx - 0.325, 0.43, rz), cab)
	_box(self, Vector3(0.68, 0.04, 2.22), Vector3(hx - 0.34, 0.88, rz), top)
	_box(self, Vector3(0.012, 0.7, 0.012), Vector3(hx - 0.655, 0.45, rz - 0.4), line)
	_box(self, Vector3(0.012, 0.7, 0.012), Vector3(hx - 0.655, 0.45, rz + 0.4), line)
	# kettle + toaster on the counter
	_cyl(self, 0.07, 0.09, 0.2, Vector3(hx - 0.34, 1.0, rz - 0.6), _mat(Color(0.85, 0.2, 0.2), 0.3, 0.3))
	_box(self, Vector3(0.22, 0.17, 0.3), Vector3(hx - 0.34, 0.99, rz + 0.5), steel)
	_obstacle(Vector2(hx - 0.325, rz), Vector2(0.65, 2.2))

	# dining table with two chairs
	var t := _root(Vector3(-1.4, 0.0, 0.5))
	var wood := _mat(Color(0.55, 0.36, 0.2), 0.45)
	_box(t, Vector3(1.2, 0.04, 0.8), Vector3(0, 0.74, 0), wood)
	for x in [-0.55, 0.55]:
		for z in [-0.35, 0.35]:
			_box(t, Vector3(0.06, 0.72, 0.06), Vector3(x, 0.36, z), wood)
	for sz in [-1.0, 1.0]:
		var c := _root(Vector3(-1.4, 0.0, 0.5 + sz * 0.62), 0.0 if sz > 0.0 else 180.0)
		_box(c, Vector3(0.42, 0.04, 0.42), Vector3(0, 0.45, 0), wood)
		_box(c, Vector3(0.42, 0.45, 0.04), Vector3(0, 0.7, 0.2), wood)
		for x in [-0.18, 0.18]:
			for z in [-0.18, 0.18]:
				_box(c, Vector3(0.04, 0.43, 0.04), Vector3(x, 0.215, z), wood)
	# fruit bowl, mug, plate
	_cyl(t, 0.16, 0.08, 0.07, Vector3(0, 0.795, 0), _mat(Color(0.9, 0.9, 0.88), 0.3))
	_sph_at(t, 0.05, Vector3(-0.05, 0.86, 0.0), _mat(Color(0.85, 0.15, 0.12), 0.4))
	_sph_at(t, 0.05, Vector3(0.05, 0.86, 0.03), _mat(Color(0.95, 0.6, 0.1), 0.4))
	_sph_at(t, 0.045, Vector3(0.0, 0.9, -0.03), _mat(Color(0.5, 0.75, 0.2), 0.4))
	_cyl(t, 0.04, 0.035, 0.09, Vector3(0.4, 0.805, 0.2), _mat(Color(0.2, 0.45, 0.75), 0.3))
	_cyl(t, 0.11, 0.11, 0.012, Vector3(-0.4, 0.766, 0.15), _mat(Color(0.95, 0.95, 0.93), 0.2))
	_obstacle(Vector2(-1.4, 0.5), Vector2(1.3, 1.8))

	# bin
	_cyl(self, 0.2, 0.17, 0.5, Vector3(hx - 0.35, 0.25, 1.0), _mat(Color(0.7, 0.72, 0.75), 0.3, 0.8))
	_obstacle(Vector2(hx - 0.35, 1.0), Vector2(0.4, 0.4))

	# windows: above the sink and on the left wall
	_window(Vector3(-2.0, 1.7, -hz), 0.0, Vector2(1.1, 0.7), false)
	_window(Vector3(-hx, 1.55, 0.3), 90.0, Vector2(1.3, 1.2), false)


func _sph_at(parent: Node3D, r: float, pos: Vector3, mat: Material) -> void:
	_sphere(parent, r, pos, mat)
