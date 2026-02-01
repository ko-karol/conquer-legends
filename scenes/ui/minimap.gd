extends Control

# Minimap component - shows player (green) and monsters (red dots)
# Size: 150x150px (from context line 66)

const MINIMAP_SIZE: float = 150.0
const PLAYER_DOT_SIZE: float = 4.0
const MONSTER_DOT_SIZE: float = 2.0

var player: CharacterBody2D = null
var world_size: Vector2 = Vector2(12000, 12000)  # From context line 59

func _ready() -> void:
	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		print("Minimap connected to player")
	else:
		print("WARNING: Minimap could not find player")

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw border
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.4, 0.6, 0.4), false, 2.0)
	
	if not player:
		return
	
	# Get player world position (convert from isometric)
	var player_world_pos = Isometric.iso_to_world(player.position)
	
	# Draw player as green dot (centered in minimap)
	var center = size / 2.0
	draw_circle(center, PLAYER_DOT_SIZE, Color(0.2, 1.0, 0.2))
	
	# Calculate visible range on minimap (show area around player)
	var map_scale = MINIMAP_SIZE / 2000.0  # Show 2000 units around player
	
	# Draw monsters as colored dots by type
	var monsters = get_tree().get_nodes_in_group("monsters")
	for monster in monsters:
		if not is_instance_valid(monster):
			continue
		
		# Get monster world position
		var monster_world_pos = Isometric.iso_to_world(monster.position)
		
		# Calculate relative position to player
		var relative_pos = monster_world_pos - player_world_pos
		
		# Skip if too far from player
		if relative_pos.length() > 2000:
			continue
		
		# Convert to minimap coordinates
		var minimap_pos = center + relative_pos * map_scale
		
		# Only draw if within minimap bounds
		if minimap_pos.x >= 0 and minimap_pos.x <= size.x and \
		   minimap_pos.y >= 0 and minimap_pos.y <= size.y:
			# Color based on monster type
			var color = Color.RED
			if monster.has_method("get_monster_color"):
				color = monster.get_monster_color()
			draw_circle(minimap_pos, MONSTER_DOT_SIZE, color)
