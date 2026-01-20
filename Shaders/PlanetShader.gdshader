// NOTE: Shader automatically converted from Godot Engine 4.5.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform bool displayInShadow = false;

void fragment() {
	ALBEDO = COLOR.rgb;
	if (displayInShadow) {
		ALBEDO = vec3(0.0);
		EMISSION = COLOR.rgb;
	}
}
