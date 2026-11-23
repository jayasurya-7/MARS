shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_lod = 2.3;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec3 c = vec3(0.0);
	float tw = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			float w = exp(-float(x * x + y * y) * 0.2);
			c += textureLod(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * px * blur_lod * 2.5, blur_lod).rgb * w;
			tw += w;
		}
	}
	c /= tw;
	// soft vignette + warm light grade
	float v = smoothstep(0.95, 0.35, distance(SCREEN_UV, vec2(0.5)) * 1.15);
	c *= mix(0.74, 1.0, v);
	c *= mix(vec3(1.0), vec3(1.07, 1.0, 0.93), 0.6);
	c = mix(vec3(dot(c, vec3(0.299, 0.587, 0.114))), c, 1.12);
	COLOR = vec4(c, 1.0);
}
