shader_type canvas_item;

uniform vec2 grid_size = vec2(100.0, 100.0);
uniform vec4 grid_color : source_color = vec4(0.2, 0.3, 0.2, 1.0);
uniform vec4 tile_color_1 : source_color = vec4(0.15, 0.22, 0.15, 1.0);
uniform vec4 tile_color_2 : source_color = vec4(0.18, 0.25, 0.18, 1.0);
uniform float grid_thickness = 2.0;

void fragment() {
	vec2 pos = UV * 10000.0; // Scale for world space
	
	// Create isometric diamond grid
	vec2 grid_pos = pos / grid_size;
	vec2 grid_id = floor(grid_pos);
	
	// Checkerboard pattern
	float checker = mod(grid_id.x + grid_id.y, 2.0);
	vec4 base_color = mix(tile_color_1, tile_color_2, checker);
	
	// Grid lines
	vec2 grid_uv = fract(grid_pos);
	float grid_line = 0.0;
	
	if (grid_uv.x < grid_thickness / grid_size.x || grid_uv.y < grid_thickness / grid_size.y) {
		grid_line = 1.0;
	}
	
	COLOR = mix(base_color, grid_color, grid_line);
}
