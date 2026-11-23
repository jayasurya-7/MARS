shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Hardwood planks (style 0) or ceramic tiles (style 1). A mask painted by FloorPainter
// (white = mopped) switches the surface from dull + dirty to glossy + wet, which
// triggers Screen Space Reflections.
uniform sampler2D clean_mask : filter_linear, repeat_disable;
uniform sampler2D grime_noise : filter_linear_mipmap, repeat_enable, hint_default_white;
uniform sampler2D grime_fine : filter_linear_mipmap, repeat_enable, hint_default_white;

uniform int floor_style = 0;
uniform vec2 floor_size_m = vec2(7.0, 5.0);

// wood
uniform float plank_w = 0.16;
uniform float plank_len = 1.3;
uniform vec3 wood_light : source_color = vec3(0.74, 0.52, 0.30);
uniform vec3 wood_dark : source_color = vec3(0.50, 0.31, 0.15);
// tile
uniform float tile_size = 0.5;
uniform vec3 tile_color : source_color = vec3(0.86, 0.88, 0.9);
uniform vec3 grout_color : source_color = vec3(0.55, 0.55, 0.56);

uniform vec3 dirt_color : source_color = vec3(0.22, 0.15, 0.09);
uniform float dirt_strength : hint_range(0.0, 1.0) = 0.0;   // 0 = clean floor (dust comes from bunnies)

uniform float dirty_roughness : hint_range(0.0, 1.0) = 0.72;
uniform float wet_roughness : hint_range(0.0, 1.0) = 0.07;
uniform float wet_metallic : hint_range(0.0, 1.0) = 0.2;
uniform float wet_specular : hint_range(0.0, 1.0) = 0.85;
uniform float wet_darken : hint_range(0.0, 1.0) = 0.14;
uniform float mask_softness : hint_range(0.01, 0.5) = 0.3;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float raw = texture(clean_mask, UV).r;
	float wet = smoothstep(0.5 - mask_softness, 0.5 + mask_softness, raw);
	vec2 m = UV * floor_size_m;

	vec3 surface;
	vec3 gap_col;
	float gap;

	if (floor_style == 0) {
		// --- staggered planks ---
		float row = floor(m.y / plank_w);
		float px = m.x + hash(vec2(row, 7.0)) * plank_len;
		float col = floor(px / plank_len);
		float rnd = hash(vec2(col, row));
		vec2 loc = vec2(fract(px / plank_len), fract(m.y / plank_w));
		float edge_m = min(min(loc.x, 1.0 - loc.x) * plank_len, min(loc.y, 1.0 - loc.y) * plank_w);
		gap = 1.0 - smoothstep(0.002, 0.007, edge_m);
		float grain = texture(grime_noise, vec2(px * 0.35 + rnd * 7.0, m.y * 6.0)).r;
		float fine = texture(grime_noise, vec2(px * 0.9, m.y * 22.0 + rnd * 3.0)).r;
		surface = mix(wood_dark, wood_light, clamp(rnd * 0.55 + grain * 0.45, 0.0, 1.0));
		surface *= 0.92 + 0.16 * fine;
		gap_col = vec3(0.07, 0.045, 0.03);
	} else {
		// --- square tiles with grout ---
		vec2 t = m / tile_size;
		vec2 id = floor(t);
		vec2 f = fract(t);
		float edge_m = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * tile_size;
		gap = 1.0 - smoothstep(0.004, 0.011, edge_m);
		float tr = hash(id);
		float vein = texture(grime_noise, m * 0.9 + tr * 5.0).r;
		surface = tile_color * (0.95 + 0.07 * tr) * (0.96 + 0.06 * vein);
		gap_col = grout_color;
	}

	// --- dirt: muddy patches + fine specks, only where not yet mopped ---
	float blotch = smoothstep(0.50, 0.72, texture(grime_noise, m * 0.28 + 3.0).r);
	float speck = smoothstep(0.60, 0.68, texture(grime_fine, m * 1.1).r);
	float dirt = clamp(blotch * 0.65 + speck * 0.8, 0.0, 1.0) * (1.0 - wet) * dirt_strength;

	vec3 base = surface;
	base = mix(base, base * vec3(0.94, 0.92, 0.9), 1.0 - wet);    // slightly dull when dry
	base = mix(base, dirt_color, dirt * 0.75);
	base *= 1.0 - wet_darken * wet;
	float rim = wet * (1.0 - wet) * 4.0;
	base *= 1.0 - rim * 0.1;
	base = mix(base, gap_col, gap * 0.85);

	ALBEDO = base;
	ROUGHNESS = mix(dirty_roughness, wet_roughness, wet);
	ROUGHNESS = mix(ROUGHNESS, 0.9, gap);
	METALLIC = wet_metallic * wet * (1.0 - gap);
	SPECULAR = mix(0.35, wet_specular, wet);
}
