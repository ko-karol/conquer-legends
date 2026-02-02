extends Resource
class_name MonsterStats

## Configuration for individual monster type stats
## Replaces hardcoded MONSTER_STATS dictionary with reusable resources
## Each monster type should have its own instance of this resource

@export var monster_name: String = "Unknown"  ## Display name
@export var base_hp: float = 100.0  ## Base hit points
@export var base_atk: float = 10.0  ## Base attack damage
@export var base_def: float = 5.0  ## Base defense
@export var base_exp: float = 10.0  ## Experience awarded on death
@export var color: Color = Color.WHITE  ## Visual color
@export var size: float = 20.0  ## Visual size (radius)
@export var speed: float = 50.0  ## Movement speed

## Level scaling multiplier applied per level (default: 1.12)
@export var level_multiplier: float = 1.12

## Calculate scaled HP based on level
func get_hp_at_level(level: int) -> float:
	return base_hp * pow(level_multiplier, level - 1)

## Calculate scaled attack based on level
func get_atk_at_level(level: int) -> float:
	return base_atk * pow(level_multiplier, level - 1)

## Calculate scaled defense based on level
func get_def_at_level(level: int) -> float:
	return base_def * pow(level_multiplier, level - 1)

## Calculate scaled experience based on level
func get_exp_at_level(level: int) -> float:
	return base_exp * pow(level_multiplier, level - 1)

## Factory method to create stats from legacy dictionary format
static func from_dict(data: Dictionary) -> MonsterStats:
	var stats = MonsterStats.new()
	stats.monster_name = data.get("name", "Unknown")
	stats.base_hp = data.get("base_hp", 100.0)
	stats.base_atk = data.get("base_atk", 10.0)
	stats.base_def = data.get("base_def", 5.0)
	stats.base_exp = data.get("base_exp", 10.0)
	stats.color = data.get("color", Color.WHITE)
	stats.size = data.get("size", 20.0)
	stats.speed = data.get("speed", 50.0)
	return stats
