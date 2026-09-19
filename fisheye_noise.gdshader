shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float distortion_strength : hint_range(0.0, 1.0) = 0.15;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.06;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float noise_speed : hint_range(0.0, 5.0) = 1.0;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 centered = SCREEN_UV * 2.0 - 1.0;
	float r2 = dot(centered, centered);

	// риб'яче око: чим далі від центру, тим сильніше "розпирає" картинку
	vec2 distorted = centered * (1.0 + distortion_strength * r2);
	vec2 final_uv = (distorted + 1.0) * 0.5;

	vec4 color;
	if (final_uv.x < 0.0 || final_uv.x > 1.0 || final_uv.y < 0.0 || final_uv.y > 1.0) {
		color = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		color = texture(screen_texture, final_uv);
	}

	// зернистий шум, що трохи "живе" в часі
	float grain = random(SCREEN_UV * vec2(1920.0, 1080.0) + TIME * noise_speed);
	color.rgb += (grain - 0.5) * noise_strength;

	// легка вінєтка, підсилює відчуття "лінзи"
	float vignette = smoothstep(1.0, 0.4, length(centered));
	color.rgb *= mix(1.0 - vignette_strength, 1.0, vignette);

	COLOR = color;
}
