// NOTE: Shader automatically converted from Godot Engine 3.5.1.stable's CanvasItemMaterial.

shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D noise : source_color, repeat_enable;
uniform int particles_anim_h_frames;
uniform int particles_anim_v_frames;
uniform bool particles_anim_loop;

varying float lifetime;

void vertex() {
	lifetime = abs(1.0-INSTANCE_CUSTOM.y);
	float h_frames = float(particles_anim_h_frames);
	float v_frames = float(particles_anim_v_frames);
	VERTEX.xy /= vec2(h_frames, v_frames);
	float particle_total_frames = float(particles_anim_h_frames * particles_anim_v_frames);
	float particle_frame = floor(INSTANCE_CUSTOM.z * float(particle_total_frames));
	if (!particles_anim_loop) {
		particle_frame = clamp(particle_frame, 0.0, particle_total_frames - 1.0);
	} else {
		particle_frame = mod(particle_frame, particle_total_frames);
	}	UV /= vec2(h_frames, v_frames);
	UV += vec2(mod(particle_frame, h_frames) / h_frames, floor((particle_frame + 0.5) / h_frames) / v_frames);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	COLOR = tex;
	COLOR.a *= clamp(mix(1.0, mix(0.5, texture(noise, UV+TIME*0.3).r, 10.0), lifetime), 0.0, 1.0);
}