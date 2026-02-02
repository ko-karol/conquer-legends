extends Resource
class_name CombatConfig

## Combat-related configuration for attacks, ranges, and cooldowns
## Centralizes all combat constants to avoid hardcoding values in scripts
## Can be customized per entity or used globally

# Attack ranges
@export var attack_range: float = 350.0  ## Maximum distance for normal attacks
@export var scatter_range: float = 400.0  ## Maximum distance for scatter skill

# Skill costs and cooldowns
@export var scatter_mp_cost: float = 5.0  ## MP cost for scatter skill
@export var scatter_cooldown: float = 0.4  ## Seconds between scatter uses
@export var auto_attack_cooldown: float = 0.8  ## Seconds between normal attacks

# Monster AI ranges
@export var aggro_range: float = 150.0  ## Distance monsters detect player
@export var monster_attack_range: float = 40.0  ## Melee attack range for monsters
@export var return_distance: float = 300.0  ## Distance from spawn before monsters return
@export var wander_radius: float = 100.0  ## Radius for idle wandering
@export var wander_wait_min: float = 1.0  ## Min seconds between wander moves
@export var wander_wait_max: float = 3.0  ## Max seconds between wander moves

## Creates a default combat configuration
static func create_default() -> CombatConfig:
	var config = CombatConfig.new()
	config.attack_range = 350.0
	config.scatter_range = 400.0
	config.scatter_mp_cost = 5.0
	config.scatter_cooldown = 0.4
	config.auto_attack_cooldown = 0.8
	config.aggro_range = 150.0
	config.monster_attack_range = 40.0
	config.return_distance = 300.0
	config.wander_radius = 100.0
	config.wander_wait_min = 1.0
	config.wander_wait_max = 3.0
	return config
