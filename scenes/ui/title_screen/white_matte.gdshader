shader_type canvas_item;
render_mode unshaded;

uniform float matte_start : hint_range(0.0, 1.0) = 0.30;
uniform float matte_end : hint_range(0.0, 1.0) = 0.85;

// The supplied JPEG exports include a white matte instead of an alpha channel.
void fragment() {
	float whiteness = min(COLOR.r, min(COLOR.g, COLOR.b));
	float opacity = 1.0 - smoothstep(matte_start, matte_end, whiteness);
	// Remove the matte's contribution at antialiased edges as well.
	COLOR.rgb = clamp((COLOR.rgb - vec3(1.0 - opacity)) / max(opacity, 0.001), 0.0, 1.0);
	COLOR.a *= opacity;
}
