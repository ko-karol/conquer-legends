extends Node
class_name CombatComponent

# Combat component - Handles damage calculation, attack stats, and combat mechanics
# Can be attached to any entity (player or monster) that needs combat functionality

signal damage_dealt(target, damage, is_crit)
signal damage_taken(amount, is_crit)
signal killed_target(target)

# Combat stats
var attack: float = 0.0
var defense: float = 0.0

# Damage range (percentage of attack)
var min_damage_percent: float = 0.8  # 80% minimum
var max_damage_percent: float = 1.2  # 120% maximum

# Crit stats
var crit_chance: float = 0.15  # 15% default
var crit_damage_multiplier: float = 1.5  # 150% damage

# Owner reference
var owner_node: Node2D = null

func _init(owner_ref: Node2D = null) -> void:
	owner_node = owner_ref

func setup(atk: float, def: float, crit_rate: float = 0.15, crit_mult: float = 1.5) -> void:
	"""Initialize combat stats"""
	attack = atk
	defense = def
	crit_chance = crit_rate
	crit_damage_multiplier = crit_mult

func calculate_damage(base_attack: float = -1.0) -> Dictionary:
	"""
	Calculate damage with min-max range and crit chance.
	Returns {damage: float, is_crit: bool}
	If base_attack is -1, uses this component's attack stat.
	"""
	var actual_attack = base_attack if base_attack >= 0.0 else attack
	
	var min_dmg = actual_attack * min_damage_percent
	var max_dmg = actual_attack * max_damage_percent
	var damage = randf_range(min_dmg, max_dmg)
	
	# Check for crit
	var is_crit = randf() < crit_chance
	if is_crit:
		damage *= crit_damage_multiplier
	
	return {"damage": damage, "is_crit": is_crit}

func apply_damage(damage: float, is_crit: bool = false) -> float:
	"""
	Apply damage to this entity (after defense reduction).
	Returns actual damage taken.
	"""
	var actual_damage = max(1, damage - defense)
	damage_taken.emit(actual_damage, is_crit)
	return actual_damage

func deal_damage_to(target: Node2D, base_attack: float = -1.0) -> Dictionary:
	"""
	Calculate and deal damage to a target.
	Returns {damage: float, is_crit: bool, actual_damage: float}
	"""
	var damage_result = calculate_damage(base_attack)
	var damage = damage_result["damage"]
	var is_crit = damage_result["is_crit"]
	
	# Apply damage to target if it has combat component or take_damage method
	var actual_damage = damage
	if target.has_node("CombatComponent"):
		var target_combat = target.get_node("CombatComponent")
		actual_damage = target_combat.apply_damage(damage, is_crit)
	elif target.has_method("take_damage"):
		target.take_damage(damage, is_crit)
	
	damage_dealt.emit(target, damage, is_crit)
	
	return {
		"damage": damage,
		"is_crit": is_crit,
		"actual_damage": actual_damage
	}

func set_attack(value: float) -> void:
	attack = value

func set_defense(value: float) -> void:
	defense = value

func increase_attack(amount: float) -> void:
	attack += amount

func increase_defense(amount: float) -> void:
	defense += amount

func get_attack() -> float:
	return attack

func get_defense() -> float:
	return defense
