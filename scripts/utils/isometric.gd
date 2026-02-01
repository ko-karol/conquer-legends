class_name Isometric

# Isometric coordinate conversion utilities
# Based on Pygame implementation (GODOT_MIGRATION_CONTEXT.md lines 83-93)

const ISO_SCALE = 0.5
const TILE_WIDTH = 64
const TILE_HEIGHT = 32

# Convert world coordinates to isometric screen coordinates
static func world_to_iso(world_pos: Vector2) -> Vector2:
	var iso_x = (world_pos.x - world_pos.y) * ISO_SCALE
	var iso_y = (world_pos.x + world_pos.y) * ISO_SCALE * 0.5
	return Vector2(iso_x, iso_y)

# Convert isometric screen coordinates to world coordinates
static func iso_to_world(iso_pos: Vector2) -> Vector2:
	var x = (iso_pos.x / ISO_SCALE + iso_pos.y / (ISO_SCALE * 0.5)) / 2.0
	var y = (iso_pos.y / (ISO_SCALE * 0.5) - iso_pos.x / ISO_SCALE) / 2.0
	return Vector2(x, y)

# Convert screen position (from camera/viewport) to world coordinates
static func screen_to_world(screen_pos: Vector2, camera: Camera2D) -> Vector2:
	# Get camera's global position and zoom
	var camera_pos = camera.global_position
	var zoom = camera.zoom.x
	
	# Convert screen position to isometric position (account for camera)
	var iso_pos = (screen_pos - get_viewport_center()) / zoom + camera_pos
	
	# Convert isometric to world
	return iso_to_world(iso_pos)

static func get_viewport_center() -> Vector2:
	var viewport = Engine.get_main_loop().root.get_viewport()
	return viewport.get_visible_rect().size / 2.0
