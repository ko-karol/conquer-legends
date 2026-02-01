extends Node

# Global game state and spawn zone management
# Autoloaded as singleton

# World constants
const WORLD_SIZE = 12000
const WORLD_CENTER = Vector2(6000, 6000)

# Spawn zone configuration
const ZONE_SPACING = 1500
const ZONE_RADIUS = 800

# Monster type definitions
enum MonsterType {
	PHEASANT,
	TURTLEDOVE,
	ROBIN,
	BANDIT,
	BANDIT_L,
	APE,
	APE_KING
}

# Spawn zones data (will be populated in _ready)
var spawn_zones: Array = []

# Active monsters tracker
var active_monsters: Array = []
var max_monsters: int = 1500

# Monster spawning
var monster_scene: PackedScene = null
var spawned_zones: Dictionary = {}  # Track monsters per zone
var world_root: Node2D = null  # Reference to main scene for spawning

func _ready() -> void:
	print("GameManager initialized")
	_create_spawn_zones()
	monster_scene = preload("res://scenes/monsters/monster.tscn")

func _create_spawn_zones() -> void:
	# Generate spawn zones on grid with 1500 unit spacing
	# Each zone has type, level range, and density based on distance from center
	
	var grid_size = int(WORLD_SIZE / ZONE_SPACING)
	
	for grid_x in range(grid_size):
		for grid_y in range(grid_size):
			var zone_x = grid_x * ZONE_SPACING + ZONE_SPACING / 2
			var zone_y = grid_y * ZONE_SPACING + ZONE_SPACING / 2
			
			var distance = Vector2(zone_x, zone_y).distance_to(WORLD_CENTER)
			var zone_data = _get_zone_config(distance)
			
			if zone_data:
				zone_data["position"] = Vector2(zone_x, zone_y)
				zone_data["radius"] = ZONE_RADIUS
				spawn_zones.append(zone_data)
	
	print("Created %d spawn zones" % spawn_zones.size())

func _get_zone_config(distance: float) -> Dictionary:
	# Returns zone configuration based on distance from center
	# Zone types: 0-1500, 1500-3000, 3000-4500, 4500-6000, 6000-7500, 7500-9000, 9000+
	
	if distance < 1500:
		return {
			"tier": 1,
			"monster_types": [MonsterType.PHEASANT, MonsterType.TURTLEDOVE],
			"level_min": 1,
			"level_max": 5,
			"density": 60
		}
	elif distance < 3000:
		return {
			"tier": 2,
			"monster_types": [MonsterType.TURTLEDOVE, MonsterType.ROBIN],
			"level_min": 3,
			"level_max": 8,
			"density": 70
		}
	elif distance < 4500:
		return {
			"tier": 3,
			"monster_types": [MonsterType.ROBIN, MonsterType.BANDIT],
			"level_min": 6,
			"level_max": 12,
			"density": 70
		}
	elif distance < 6000:
		return {
			"tier": 4,
			"monster_types": [MonsterType.BANDIT, MonsterType.BANDIT_L],
			"level_min": 10,
			"level_max": 18,
			"density": 65
		}
	elif distance < 7500:
		return {
			"tier": 5,
			"monster_types": [MonsterType.BANDIT_L, MonsterType.APE],
			"level_min": 15,
			"level_max": 25,
			"density": 60
		}
	elif distance < 9000:
		return {
			"tier": 6,
			"monster_types": [MonsterType.APE, MonsterType.APE_KING],
			"level_min": 25,
			"level_max": 40,
			"density": 50
		}
	else:
		return {
			"tier": 7,
			"monster_types": [MonsterType.APE_KING],
			"level_min": 40,
			"level_max": 80,
			"density": 40
		}

func get_zones_near_position(pos: Vector2, radius: float) -> Array:
	# Returns spawn zones within radius of position
	var nearby_zones = []
	for zone in spawn_zones:
		if zone["position"].distance_to(pos) < radius + ZONE_RADIUS:
			nearby_zones.append(zone)
	return nearby_zones

func register_monster(monster: Node2D) -> void:
	if not active_monsters.has(monster):
		active_monsters.append(monster)

func unregister_monster(monster: Node2D) -> void:
	active_monsters.erase(monster)

func get_monster_count() -> int:
	return active_monsters.size()

func set_world_root(root: Node2D) -> void:
	world_root = root

func spawn_monsters_near_player(player_world_pos: Vector2) -> void:
	if not world_root or not monster_scene:
		return
	
	# Get zones near player (spawn radius: 2000 units)
	var nearby_zones = get_zones_near_position(player_world_pos, 2000)
	
	for zone in nearby_zones:
		var zone_key = str(zone["position"])
		
		# Check if zone already spawned
		if not spawned_zones.has(zone_key):
			spawned_zones[zone_key] = []
		
		# Count alive monsters in this zone
		var alive_count = 0
		for monster in spawned_zones[zone_key]:
			if is_instance_valid(monster):
				alive_count += 1
		
		# Spawn monsters if below density
		var target_count = int(zone["density"] * 0.5)  # Start with 50% density for testing
		var to_spawn = target_count - alive_count
		
		if to_spawn > 0 and get_monster_count() < max_monsters:
			_spawn_monsters_in_zone(zone, to_spawn, zone_key)

func _spawn_monsters_in_zone(zone: Dictionary, count: int, zone_key: String) -> void:
	for i in range(count):
		if get_monster_count() >= max_monsters:
			break
		
		# Pick random monster type from zone
		var monster_type = zone["monster_types"].pick_random()
		
		# Pick random level in zone range
		var level = randi_range(zone["level_min"], zone["level_max"])
		
		# Pick random position within zone radius
		var angle = randf() * TAU
		var distance = randf() * zone["radius"]
		var spawn_offset = Vector2(cos(angle), sin(angle)) * distance
		var spawn_pos = zone["position"] + spawn_offset
		
		# Instantiate monster
		var monster = monster_scene.instantiate()
		world_root.add_child(monster)
		monster.initialize(monster_type, level, spawn_pos)
		
		# Track in zone
		spawned_zones[zone_key].append(monster)

func cleanup_distant_monsters(player_world_pos: Vector2, cleanup_radius: float = 3000) -> void:
	# Remove monsters far from player to maintain performance
	for monster in active_monsters.duplicate():
		if not is_instance_valid(monster):
			continue
		
		var monster_world_pos = Isometric.iso_to_world(monster.position)
		if monster_world_pos.distance_to(player_world_pos) > cleanup_radius:
			monster.queue_free()
