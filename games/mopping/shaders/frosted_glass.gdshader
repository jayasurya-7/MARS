shader_type canvas_item;

// Samples the already-rendered 3D world behind the UI. Mipmaps give a cheap, wide blur.
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float blur_lod : hint_range(0.0, 7.0) = 3.5;
uniform float blur_spread : hint_range(0.0, 8.0) = 1.5;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 0.38);
uniform float corner_radius = 28.0;
uniform float border_width = 2.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 0.65);
uniform vec2 panel_size = vec2(300.0, 100.0);   // set from script on resize

float rounded_box_sdf(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + vec2(r);
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = (UV - 0.5) * panel_size;
	float d = rounded_box_sdf(p, panel_size * 0.5, corner_radius);
	float shape = 1.0 - smoothstep(-1.0, 0.0, d);

	// 9-tap blur on a blurred mip level.
	vec2 px = SCREEN_PIXEL_SIZE * blur_spread * exp2(blur_lod);
	vec3 acc = vec3(0.0);
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			acc += textureLod(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * px, blur_lod).rgb;
		}
	}
	vec3 blurred = acc / 9.0;

	vec3 col = mix(blurred, tint_color.rgb, tint_color.a);
	float edge = smoothstep(-border_width - 1.0, -border_width, d) * shape;   // thin bright rim
	col = mix(col, border_color.rgb, edge * border_color.a);

	// Subtle top-down sheen.
	col += vec3(0.06) * (1.0 - UV.y);

	COLOR = vec4(col, shape);
}
