extends Resource
class_name MonsterConfig

## Global monster configuration with stats for all monster types
## Replaces the MONSTER_STATS dictionary in monster.gd
## Provides centralized access to monster stats via MonsterType enum

# Monster stats indexed by GameManager.MonsterType
var stats: Dictionary = {}

func _init() -> void:
	_initialize_default_stats()

## Initialize with default monster stats (matching original values)
func _initialize_default_stats() -> void:
	# Pheasant - Weakest, brown bird
	var pheasant = MonsterStats.new()
	pheasant.monster_name = "Pheasant"
	pheasant.base_hp = 30.0
	pheasant.base_atk = 5.0
	pheasant.base_def = 5.0
	pheasant.base_exp = 8.0
	pheasant.color = Color(0.6, 0.4, 0.2)
	pheasant.size = 18.0
	pheasant.speed = 40.0
	stats[GameManager.MonsterType.PHEASANT] = pheasant
	
	# Turtledove - Gray bird
	var turtledove = MonsterStats.new()
	turtledove.monster_name = "Turtledove"
	turtledove.base_hp = 50.0
	turtledove.base_atk = 10.0
	turtledove.base_def = 8.0
	turtledove.base_exp = 15.0
	turtledove.color = Color(0.5, 0.5, 0.5)
	turtledove.size = 20.0
	turtledove.speed = 50.0
	stats[GameManager.MonsterType.TURTLEDOVE] = turtledove
	
	# Robin - Orange bird
	var robin = MonsterStats.new()
	robin.monster_name = "Robin"
	robin.base_hp = 80.0
	robin.base_atk = 18.0
	robin.base_def = 12.0
	robin.base_exp = 25.0
	robin.color = Color(1.0, 0.5, 0.2)
	robin.size = 22.0
	robin.speed = 60.0
	stats[GameManager.MonsterType.ROBIN] = robin
	
	# Bandit - Dark red humanoid
	var bandit = MonsterStats.new()
	bandit.monster_name = "Bandit"
	bandit.base_hp = 120.0
	bandit.base_atk = 28.0
	bandit.base_def = 20.0
	bandit.base_exp = 40.0
	bandit.color = Color(0.5, 0.1, 0.1)
	bandit.size = 28.0
	bandit.speed = 70.0
	stats[GameManager.MonsterType.BANDIT] = bandit
	
	# BanditL - Purple elite bandit
	var bandit_l = MonsterStats.new()
	bandit_l.monster_name = "BanditL"
	bandit_l.base_hp = 200.0
	bandit_l.base_atk = 45.0
	bandit_l.base_def = 35.0
	bandit_l.base_exp = 80.0
	bandit_l.color = Color(0.5, 0.2, 0.6)
	bandit_l.size = 32.0
	bandit_l.speed = 80.0
	stats[GameManager.MonsterType.BANDIT_L] = bandit_l
	
	# Ape - Dark brown primate
	var ape = MonsterStats.new()
	ape.monster_name = "Ape"
	ape.base_hp = 350.0
	ape.base_atk = 65.0
	ape.base_def = 50.0
	ape.base_exp = 150.0
	ape.color = Color(0.3, 0.2, 0.1)
	ape.size = 38.0
	ape.speed = 90.0
	stats[GameManager.MonsterType.APE] = ape
	
	# ApeKing - Red boss ape
	var ape_king = MonsterStats.new()
	ape_king.monster_name = "ApeKing"
	ape_king.base_hp = 800.0
	ape_king.base_atk = 120.0
	ape_king.base_def = 80.0
	ape_king.base_exp = 500.0
	ape_king.color = Color(0.8, 0.1, 0.1)
	ape_king.size = 50.0
	ape_king.speed = 60.0
	stats[GameManager.MonsterType.APE_KING] = ape_king

## Get stats for a monster type
func get_stats(monster_type: GameManager.MonsterType) -> MonsterStats:
	return stats.get(monster_type, null)

## Check if stats exist for a monster type
func has_stats(monster_type: GameManager.MonsterType) -> bool:
	return stats.has(monster_type)
