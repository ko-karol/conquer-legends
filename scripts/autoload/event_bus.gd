extends Node

# Global event bus for decoupled communication
# Reduces tight coupling between game systems

# ============================================================
# COMBAT EVENTS
# ============================================================

## Emitted when any entity takes damage
## damage: float - Amount of damage taken
## target: Node - Entity that took damage
## source: Node - Entity that dealt damage (can be null)
## is_crit: bool - Whether damage was critical
signal damage_taken(damage: float, target: Node, source: Node, is_crit: bool)

## Emitted when any entity dies
## victim: Node - Entity that died
## killer: Node - Entity that caused death (can be null)
signal entity_died(victim: Node, killer: Node)

## Emitted when player attacks
## target: Node - Attack target
## damage: float - Damage amount
## is_crit: bool - Whether attack was critical
signal player_attacked(target: Node, damage: float, is_crit: bool)

## Emitted when player uses scatter skill
## num_targets: int - Number of targets hit
## total_damage: float - Total damage dealt
signal player_scatter_used(num_targets: int, total_damage: float)

## Emitted when monster attacks player
## monster: Node - Attacking monster
## damage: float - Damage amount
signal monster_attacked(monster: Node, damage: float)

# ============================================================
# PLAYER EVENTS
# ============================================================

## Emitted when player stats change (HP, MP, etc.)
## player: Node - Player reference
signal player_stats_changed(player: Node)

## Emitted when player levels up
## new_level: int - Player's new level
signal player_leveled_up(new_level: int)

## Emitted when player gains experience
## exp_amount: float - Amount of EXP gained
signal player_gained_exp(exp_amount: float)

## Emitted when player MP changes (skills, regen)
## current_mp: float - Current MP value
## max_mp: float - Maximum MP value
signal player_mp_changed(current_mp: float, max_mp: float)

## Emitted when player HP changes
## current_hp: float - Current HP value
## max_hp: float - Maximum HP value
signal player_hp_changed(current_hp: float, max_hp: float)

## Emitted when player selects a target
## target: Node - Selected target (null if cleared)
signal player_target_changed(target: Node)

# ============================================================
# MONSTER EVENTS
# ============================================================

## Emitted when a monster spawns
## monster: Node - Spawned monster
## monster_type: int - GameManager.MonsterType enum value
## level: int - Monster level
signal monster_spawned(monster: Node, monster_type: int, level: int)

## Emitted when a monster is removed/despawned
## monster: Node - Monster being removed
signal monster_despawned(monster: Node)

## Emitted when monster changes AI state
## monster: Node - Monster reference
## old_state: int - Previous state enum value
## new_state: int - New state enum value
signal monster_state_changed(monster: Node, old_state: int, new_state: int)

# ============================================================
# VISUAL EFFECTS EVENTS
# ============================================================

## Request camera shake
## amount: float - Shake intensity
signal camera_shake_requested(amount: float)

## Request particle spawn
## particle_type: String - Particle scene name
## world_position: Vector2 - Position in world coordinates
signal particle_spawn_requested(particle_type: String, world_position: Vector2)

## Request damage number display
## damage: float - Damage amount
## position: Vector2 - Position to display at
## is_crit: bool - Whether damage was critical
signal damage_number_requested(damage: float, position: Vector2, is_crit: bool)

# ============================================================
# UI EVENTS
# ============================================================

## Emitted when UI needs to refresh player display
signal ui_refresh_requested()

## Emitted when skill cooldown changes
## skill_name: String - Name of skill
## cooldown_remaining: float - Time remaining on cooldown
signal skill_cooldown_changed(skill_name: String, cooldown_remaining: float)

# ============================================================
# SYSTEM EVENTS
# ============================================================

## Emitted when game is paused/unpaused
## is_paused: bool - New pause state
signal game_paused(is_paused: bool)

## Emitted when debug mode toggles
## debug_enabled: bool - New debug state
signal debug_mode_toggled(debug_enabled: bool)

# ============================================================
# HELPER METHODS
# ============================================================

func _ready() -> void:
	print("EventBus initialized")

## Helper to emit damage event with all context
func emit_damage(damage: float, target: Node, source: Node = null, is_crit: bool = false) -> void:
	damage_taken.emit(damage, target, source, is_crit)

## Helper to emit entity death with killer context
func emit_death(victim: Node, killer: Node = null) -> void:
	entity_died.emit(victim, killer)

## Helper to request camera shake
func shake_camera(amount: float) -> void:
	camera_shake_requested.emit(amount)

## Helper to spawn particles
func spawn_particles(particle_type: String, world_pos: Vector2) -> void:
	particle_spawn_requested.emit(particle_type, world_pos)
