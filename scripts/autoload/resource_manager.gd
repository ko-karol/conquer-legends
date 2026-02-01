extends Node

# ResourceManager - Centralized asset loading and caching
# Singleton that manages all game resources (scenes, sounds, textures, etc.)

# ===== SCENES =====
var scenes: Dictionary = {}

# ===== SOUNDS =====
var sounds: Dictionary = {}

# ===== INITIALIZATION =====
func _ready() -> void:
	_load_scenes()
	_load_sounds()
	print("ResourceManager initialized with %d scenes and %d sounds" % [scenes.size(), sounds.size()])

func _load_scenes() -> void:
	"""Preload all scene resources"""
	# Projectiles
	scenes["arrow"] = preload("res://scenes/projectiles/arrow.tscn")
	
	# Effects
	scenes["damage_number"] = preload("res://scenes/effects/damage_number.tscn")
	scenes["muzzle_flash"] = preload("res://scenes/effects/muzzle_flash.tscn")
	scenes["hit_particles"] = preload("res://scenes/effects/hit_particles.tscn")
	scenes["death_burst"] = preload("res://scenes/effects/death_burst.tscn")
	scenes["levelup_burst"] = preload("res://scenes/effects/levelup_burst.tscn")
	
	# Monsters
	scenes["monster"] = preload("res://scenes/monsters/monster.tscn")

func _load_sounds() -> void:
	"""Preload all sound resources"""
	# Note: Sound files are optional - if they don't exist, sounds will be null
	# This allows the game to run without audio assets
	
	# Player sounds
	sounds["arrow_shoot"] = _safe_load("res://assets/sounds/arrow_shoot.ogg")
	sounds["levelup"] = _safe_load("res://assets/sounds/levelup.ogg")
	
	# Monster sounds
	sounds["hit"] = _safe_load("res://assets/sounds/hit.ogg")
	sounds["death"] = _safe_load("res://assets/sounds/death.ogg")

func _safe_load(path: String) -> Resource:
	"""Safely load a resource, returning null if it doesn't exist"""
	if ResourceLoader.exists(path):
		return load(path)
	else:
		push_warning("ResourceManager: Optional resource not found: %s" % path)
		return null

# ===== PUBLIC API =====

func get_scene(scene_name: String) -> PackedScene:
	"""Get a scene by name. Returns null if not found."""
	if not scenes.has(scene_name):
		push_error("ResourceManager: Scene '%s' not found" % scene_name)
		return null
	return scenes[scene_name]

func get_sound(sound_name: String) -> AudioStream:
	"""Get a sound by name. Returns null if not found or if audio file doesn't exist."""
	if not sounds.has(sound_name):
		push_error("ResourceManager: Sound '%s' not found in registry" % sound_name)
		return null
	return sounds[sound_name]  # May be null if file doesn't exist

func instantiate_scene(scene_name: String) -> Node:
	"""Convenience method to get and instantiate a scene in one call"""
	var scene = get_scene(scene_name)
	if scene:
		return scene.instantiate()
	return null

# ===== VALIDATION =====

func validate_resources() -> bool:
	"""Validate that all resources loaded successfully. Returns true if all valid."""
	var all_valid = true
	
	for scene_name in scenes.keys():
		if scenes[scene_name] == null:
			push_error("ResourceManager: Failed to load scene '%s'" % scene_name)
			all_valid = false
	
	for sound_name in sounds.keys():
		if sounds[sound_name] == null:
			push_error("ResourceManager: Failed to load sound '%s'" % sound_name)
			all_valid = false
	
	return all_valid
