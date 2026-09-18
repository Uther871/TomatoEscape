shader_type canvas_item;

uniform vec2 shadow_offset = vec2(1.0, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.35);

void fragment() {
	vec2 pixel_size = TEXTURE_PIXEL_SIZE * shadow_offset;
	vec4 base = texture(TEXTURE, UV);

	if (base.a > 0.0) {
		COLOR = base;
	} else {
		vec4 shadow_source = texture(TEXTURE, UV - pixel_size);
		COLOR = vec4(shadow_color.rgb, shadow_color.a * shadow_source.a);
	}
}