extends Node2D

# Main game scene controller

@onready var camera: Camera2D = $Camera2D

# Player reference
var player: CharacterBody2D = null

# Zoom settings
const ZOOM_MIN = 0.5
const ZOOM_MAX = 2.0
const ZOOM_STEP = 0.1
var current_zoom = 1.0

# Screen shake
var shake_amount = 0.0
var shake_decay = 5.0

# Debug mode
var debug_mode = false  # Disable debug markers now that we have player
var click_markers: Array = []
const MAX_MARKERS = 10

func _ready() -> void:
	print("Main scene loaded")
	# Set background color
	RenderingServer.set_default_clear_color(Color(0.15, 0.15, 0.2))
	
	# Set world root in GameManager
	GameManager.set_world_root(self)
	
	# Get player reference from scene tree
	player = get_node("Player")
	
	# Add player to group for monster aggro
	if player:
		player.add_to_group("player")
	
	# Connect to event bus
	EventBus.camera_shake_requested.connect(_on_camera_shake_requested)
	EventBus.particle_spawn_requested.connect(_on_particle_spawn_requested)
	EventBus.damage_number_requested.connect(_on_damage_number_requested)

func _input(event: InputEvent) -> void:
	# Handle zoom controls
	if event.is_action_pressed("zoom_in"):
		_zoom(ZOOM_STEP)
	elif event.is_action_pressed("zoom_out"):
		_zoom(-ZOOM_STEP)
	elif event.is_action_pressed("zoom_reset"):
		_set_zoom(1.0)
	
	# Player input
	if player and event is InputEventMouseButton and event.pressed:
		var world_pos = Isometric.screen_to_world(event.position, camera)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Check if clicking on a monster
			var clicked_monster = _get_monster_at_position(event.position)
			
			if clicked_monster:
				# Select monster as target (Conquer Online style)
				player.select_target(clicked_monster)
			elif event.ctrl_pressed:
				# Ctrl+Click = Jump (and clear target)
				player.clear_target()
				player.jump_to(world_pos)
			else:
				# Click = Move (and clear target)
				player.clear_target()
				player.move_to(world_pos)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right click = Scatter skill
			player.scatter_skill(world_pos)
	
	# Debug: click to show coordinate conversion
	if debug_mode and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.ctrl_pressed:
			_debug_click(event.position)

func _zoom(delta: float) -> void:
	_set_zoom(current_zoom + delta)

func _set_zoom(new_zoom: float) -> void:
	current_zoom = clamp(new_zoom, ZOOM_MIN, ZOOM_MAX)
	camera.zoom = Vector2(current_zoom, current_zoom)

func _debug_click(screen_pos: Vector2) -> void:
	# Convert screen position to world coordinates
	var world_pos = Isometric.screen_to_world(screen_pos, camera)
	var iso_pos = Isometric.world_to_iso(world_pos)
	
	print("Click: Screen=%s  World=%s  Iso=%s" % [screen_pos, world_pos, iso_pos])
	
	# Create visual marker at click position
	_add_debug_marker(iso_pos, world_pos)

func _add_debug_marker(iso_pos: Vector2, world_pos: Vector2) -> void:
	# Remove oldest marker if at max
	if click_markers.size() >= MAX_MARKERS:
		var old_marker = click_markers.pop_front()
		old_marker.queue_free()
	
	# Create marker node
	var marker = Node2D.new()
	marker.position = iso_pos
	add_child(marker)
	click_markers.append(marker)
	
	# Add visual representation
	marker.z_index = 100

func _draw() -> void:
	if not debug_mode:
		return
	
	# Draw debug grid in isometric space
	_draw_debug_grid()
	
	# Draw click markers
	for marker in click_markers:
		if is_instance_valid(marker):
			var pos = marker.position
			# Draw cross at marker position
			draw_line(pos + Vector2(-10, 0), pos + Vector2(10, 0), Color.GREEN, 2.0)
			draw_line(pos + Vector2(0, -10), pos + Vector2(0, 10), Color.GREEN, 2.0)
			# Draw circle
			draw_circle(pos, 5, Color(0, 1, 0, 0.5))

func _draw_debug_grid() -> void:
	# Draw a small isometric grid at world center to verify coordinate system
	var world_center = Vector2(6000, 6000)
	var grid_size = 1000
	var grid_spacing = 500
	
	for x in range(-grid_size, grid_size + 1, grid_spacing):
		for y in range(-grid_size, grid_size + 1, grid_spacing):
			var world_pos = world_center + Vector2(x, y)
			var iso_pos = Isometric.world_to_iso(world_pos)
			
			# Draw small dot at grid intersection
			draw_circle(iso_pos, 2, Color(0.5, 0.5, 0.5, 0.3))

func _process(delta: float) -> void:
	# Camera follows player with screen shake
	if player:
		var target_pos = player.position
		
		# Apply screen shake
		if shake_amount > 0:
			shake_amount = max(0, shake_amount - shake_decay * delta)
			target_pos += Vector2(
				randf_range(-shake_amount, shake_amount),
				randf_range(-shake_amount, shake_amount)
			)
		
		camera.position = target_pos
		
		# Spawn monsters near player
		var player_world_pos = Isometric.iso_to_world(player.position)
		GameManager.spawn_monsters_near_player(player_world_pos)
	
	if debug_mode:
		queue_redraw()

func shake_camera(amount: float) -> void:
	shake_amount = amount

# Event handlers

func _on_camera_shake_requested(amount: float) -> void:
	shake_camera(amount)

func _on_particle_spawn_requested(particle_type: String, world_pos: Vector2) -> void:
	var particles = ResourceManager.instantiate_scene(particle_type)
	if particles:
		var iso_pos = Isometric.world_to_iso(world_pos)
		add_child(particles)
		particles.position = iso_pos
		particles.emitting = true
		
		# Auto-remove after lifetime
		if "lifetime" in particles:
			await get_tree().create_timer(particles.lifetime + 0.1).timeout
			if is_instance_valid(particles):
				particles.queue_free()

func _on_damage_number_requested(damage: float, iso_pos: Vector2, is_crit: bool) -> void:
	var damage_number = ResourceManager.instantiate_scene("damage_number")
	if damage_number:
		add_child(damage_number)
		damage_number.position = iso_pos
		damage_number.setup(damage, is_crit)

func _get_monster_at_position(screen_pos: Vector2) -> Node2D:
	# Check if click is on a monster
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	
	# Convert screen to world position
	var world_pos = Isometric.screen_to_world(screen_pos, camera)
	var iso_pos = Isometric.world_to_iso(world_pos)
	query.position = iso_pos
	query.collision_mask = 2  # Monster layer
	
	var results = space_state.intersect_point(query, 1)
	
	if results.size() > 0:
		var collider = results[0].collider
		# Check if it's a monster (has take_damage method)
		if collider.has_method("take_damage"):
			return collider
	
	return null
