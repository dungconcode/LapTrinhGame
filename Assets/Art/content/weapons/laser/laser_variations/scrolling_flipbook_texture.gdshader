shader_type canvas_item;

uniform float scroll_speed = 0.f;
uniform int h_frames : hint_range(1, 64) = 1;
uniform int v_frames : hint_range(1, 64) = 1;
uniform float fps = 10.f;

void vertex() {
	float time_per_frame = 1.f / fps;
	int frame_count = h_frames * v_frames;
	int frame = int(TIME / time_per_frame);
	int h_frame = frame % h_frames;
	int v_frame = (frame / h_frames) % v_frames;
	
	float f_v_frame = float(v_frame);
	float f_v_frames = float(v_frames);
	
	UV.x += float(h_frame) / float(h_frames);
	UV.x -= TIME * scroll_speed;
	UV.y = UV.y / f_v_frames + f_v_frame / f_v_frames;
	// inverts x axis
	VERTEX.x /= f_v_frames;
}