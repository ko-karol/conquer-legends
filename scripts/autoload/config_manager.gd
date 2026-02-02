extends Node

## ConfigManager - Global configuration singleton
## Provides centralized access to all game configuration resources
## Ensures consistent config values across all systems

var player_config: PlayerConfig
var combat_config: CombatConfig
var monster_config: MonsterConfig

func _ready() -> void:
	_initialize_configs()
	print("ConfigManager initialized")

func _initialize_configs() -> void:
	# Create default configurations
	player_config = PlayerConfig.create_default()
	combat_config = CombatConfig.create_default()
	monster_config = MonsterConfig.new()
	
	# TODO: In the future, these could be loaded from .tres files
	# to allow designers to customize values without code changes:
	# player_config = load("res://config/player_config.tres")
	# combat_config = load("res://config/combat_config.tres")

func get_player_config() -> PlayerConfig:
	return player_config

func get_combat_config() -> CombatConfig:
	return combat_config

func get_monster_config() -> MonsterConfig:
	return monster_config

func get_monster_stats(monster_type: GameManager.MonsterType) -> MonsterStats:
	return monster_config.get_stats(monster_type)
