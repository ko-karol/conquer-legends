extends CharacterBody2D

# Monster with AI state machine
# Based on Pygame implementation (GODOT_MIGRATION_CONTEXT.md lines 109-117)

# Monster stats (from lines 109-117)
const MONSTER_STATS = {
	GameManager.MonsterType.PHEASANT: {
		"name": "Pheasant",
		"base_hp": 30.0,
		"base_atk": 5.0,
		"base_exp": 8.0,
		"color": Color(0.6, 0.4, 0.2),  # Brown
		"size": 18.0,
		"speed": 40.0
	},
	GameManager.MonsterType.TURTLEDOVE: {
		"name": "Turtledove",
		"base_hp": 50.0,
		"base_atk": 10.0,
		"base_exp": 15.0,
		"color": Color(0.5, 0.5, 0.5),  # Gray
		"size": 20.0,
		"speed": 50.0
	},
	GameManager.MonsterType.ROBIN: {
		"name": "Robin",
		"base_hp": 80.0,
		"base_atk": 18.0,
		"base_exp": 25.0,
		"color": Color(1.0, 0.5, 0.2),  # Orange
		"size": 22.0,
		"speed": 60.0
	},
	GameManager.MonsterType.BANDIT: {
		"name": "Bandit",
		"base_hp": 120.0,
		"base_atk": 28.0,
		"base_exp": 40.0,
		"color": Color(0.5, 0.1, 0.1),  # Dark red
		"size": 28.0,
		"speed": 70.0
	},
	GameManager.MonsterType.BANDIT_L: {
		"name": "BanditL",
		"base_hp": 200.0,
		"base_atk": 45.0,
		"base_exp": 80.0,
		"color": Color(0.5, 0.2, 0.6),  # Purple
		"size": 32.0,
		"speed": 80.0
	},
	GameManager.MonsterType.APE: {
		"name": "Ape",
		"base_hp": 350.0,
		"base_atk": 65.0,
		"base_exp": 150.0,
		"color": Color(0.3, 0.2, 0.1),  # Dark brown
		"size": 38.0,
		"speed": 90.0
	},
	GameManager.MonsterType.APE_KING: {
		"name": "ApeKing",
		"base_hp": 800.0,
		"base_atk": 120.0,
		"base_exp": 500.0,
		"color": Color(0.8, 0.1, 0.1),  # Red
		"size": 50.0,
		"speed": 60.0
	}
}

# AI constants (from context)
const AGGRO_RANGE = 150.0
const ATTACK_RANGE = 40.0
const RETURN_DISTANCE = 300.0  # Distance from spawn before returning
const WANDER_RADIUS = 100.0
const WANDER_WAIT_MIN = 1.0
const WANDER_WAIT_MAX = 3.0

# Level scaling (1.12x per level)
const LEVEL_MULTIPLIER = 1.12

# Note: All resources now loaded via ResourceManager singleton

# AI States
enum State { WANDER, CHASE, ATTACK, RETURN, DEAD }

# Monster properties
var monster_type: int = GameManager.MonsterType.PHEASANT
var level: int = 1
var max_hp: float = 30.0
var hp: float = 30.0
var exp_reward: float = 8.0
var move_speed: float = 40.0
var size: float = 18.0
var color: Color = Color.WHITE

# Combat component (optional - monsters use simple stats for now)
var combat: CombatComponent = null

# AI state
var current_state: State = State.WANDER
var spawn_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var target_player: CharacterBody2D = null

# Visual elements
@onready var visual: Node2D = $Visual
@onready var body_shape: Polygon2D = $Visual/Body
@onready var shadow_shape: Polygon2D = $Visual/Shadow
@onready var name_label: Label = $Visual/NameLabel
@onready var health_bar_bg: ColorRect = $Visual/HealthBarBg
@onready var health_bar_fill: ColorRect = $Visual/HealthBarFill
@onready var aggro_range: Area2D = $AggroRange
@onready var attack_range: Area2D = $AttackRange

# Selection state (no visual indicator)
var is_selected: bool = false

# Audio
@onready var hit_sound: AudioStreamPlayer = $HitSound
@onready var death_sound: AudioStreamPlayer = $DeathSound

func _ready() -> void:
	# Will be initialized when spawned
	pass

func initialize(type: int, spawn_level: int, world_spawn_pos: Vector2) -> void:
	monster_type = type
	level = spawn_level
	
	# Get base stats
	var stats = MONSTER_STATS[type]
	
	# Apply level scaling (1.12x per level)
	var scale_factor = pow(LEVEL_MULTIPLIER, level - 1)
	max_hp = stats["base_hp"] * scale_factor
	hp = max_hp
	var attack_value = stats["base_atk"] * scale_factor
	exp_reward = stats["base_exp"] * scale_factor
	move_speed = stats["speed"]
	size = stats["size"]
	color = stats["color"]
	
	# Initialize combat component for monsters
	combat = CombatComponent.new(self)
	combat.setup(attack_value, 0.0, 0.05, 1.3)  # Lower crit chance/mult for monsters
	add_child(combat)
	
	# Set spawn position
	var iso_pos = Isometric.world_to_iso(world_spawn_pos)
	position = iso_pos
	spawn_position = iso_pos
	
	# Setup visuals
	_setup_visuals()
	
	# Setup collision shapes
	_setup_collision()
	
	# Load sound effects from ResourceManager
	hit_sound.stream = ResourceManager.get_sound("hit")
	death_sound.stream = ResourceManager.get_sound("death")
	
	# Register with GameManager
	GameManager.register_monster(self)
	
	# Add to monsters group for scatter targeting
	add_to_group("monsters")
	
	# Emit spawn event
	EventBus.monster_spawned.emit(self, monster_type, level)
	
	# Start wandering
	current_state = State.WANDER
	_start_wander()

func _setup_visuals() -> void:
	# Simple hexagonal shape for isometric creatures
	var points = PackedVector2Array()
	var segments = 6
	for i in range(segments):
		var angle = (i / float(segments)) * TAU - PI/2
		points.append(Vector2(cos(angle), sin(angle) * 1.3) * size)
	body_shape.polygon = points
	body_shape.color = color
	
	# Shadow: ellipse at base
	var shadow_points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		shadow_points.append(Vector2(cos(angle) * size * 0.8, sin(angle) * size * 0.4 + size * 1.2))
	shadow_shape.polygon = shadow_points
	
	# Setup name label
	var stats = MONSTER_STATS[monster_type]
	name_label.text = stats["name"]
	
	# Position UI elements above monster
	var ui_y_offset = -size - 20
	name_label.position.y = ui_y_offset - 20
	health_bar_bg.position.y = ui_y_offset
	health_bar_fill.position.y = ui_y_offset

func _setup_collision() -> void:
	# Body collision
	var collision = $CollisionShape2D
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = size
	collision.shape = circle_shape
	
	# Aggro range
	var aggro_collision = $AggroRange/AggroCollision
	var aggro_circle = CircleShape2D.new()
	aggro_circle.radius = AGGRO_RANGE
	aggro_collision.shape = aggro_circle
	
	# Attack range
	var attack_collision = $AttackRange/AttackCollision
	var attack_circle = CircleShape2D.new()
	attack_circle.radius = ATTACK_RANGE
	attack_collision.shape = attack_circle
	
	# Connect signals
	aggro_range.body_entered.connect(_on_aggro_range_entered)
	aggro_range.body_exited.connect(_on_aggro_range_exited)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	# Update health bar
	_update_health_bar()
	
	# Update AI state machine
	match current_state:
		State.WANDER:
			_update_wander(delta)
		State.CHASE:
			_update_chase(delta)
		State.ATTACK:
			_update_attack(delta)
		State.RETURN:
			_update_return(delta)

func _update_wander(delta: float) -> void:
	wander_timer -= delta
	
	if wander_timer <= 0:
		_start_wander()
	else:
		# Move toward wander target
		var to_target = target_position - position
		if to_target.length() > 5:
			velocity = to_target.normalized() * move_speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO

func _start_wander() -> void:
	# Pick random position near spawn
	var random_offset = Vector2(
		randf_range(-WANDER_RADIUS, WANDER_RADIUS),
		randf_range(-WANDER_RADIUS, WANDER_RADIUS)
	)
	target_position = spawn_position + random_offset
	wander_timer = randf_range(WANDER_WAIT_MIN, WANDER_WAIT_MAX)

func _update_chase(_delta: float) -> void:
	if not is_instance_valid(target_player):
		current_state = State.WANDER
		return
	
	# Check if too far from spawn
	if position.distance_to(spawn_position) > RETURN_DISTANCE:
		current_state = State.RETURN
		return
	
	# Check if in attack range
	if position.distance_to(target_player.position) <= ATTACK_RANGE:
		current_state = State.ATTACK
		return
	
	# Chase player
	var to_player = target_player.position - position
	velocity = to_player.normalized() * move_speed
	move_and_slide()

func _update_attack(_delta: float) -> void:
	if not is_instance_valid(target_player):
		current_state = State.WANDER
		return
	
	# Check if player out of attack range
	var dist_to_player = position.distance_to(target_player.position)
	if dist_to_player > ATTACK_RANGE:
		current_state = State.CHASE
		return
	
	# Stop and attack (Phase 5 will add actual attack logic)
	velocity = Vector2.ZERO
	
	# Placeholder: face player
	# TODO: Implement attack cooldown and damage dealing in Phase 5

func _update_return(_delta: float) -> void:
	# Return to spawn position
	var to_spawn = spawn_position - position
	
	if to_spawn.length() < 10:
		# Reached spawn, resume wandering
		current_state = State.WANDER
		hp = max_hp  # Heal when returning
		target_player = null
		_start_wander()
		return
	
	velocity = to_spawn.normalized() * move_speed
	move_and_slide()

func _update_health_bar() -> void:
	# Update health bar width based on current HP
	var health_percent = hp / max_hp
	var bar_width = 50.0  # Total width
	health_bar_fill.size.x = bar_width * health_percent
	health_bar_fill.offset_right = health_bar_fill.offset_left + health_bar_fill.size.x

func _on_aggro_range_entered(body: Node2D) -> void:
	if current_state == State.DEAD or current_state == State.RETURN:
		return
	
	# Check if it's the player
	if body.is_in_group("player") or body.name == "Player":
		target_player = body
		current_state = State.CHASE

func _on_aggro_range_exited(_body: Node2D) -> void:
	# Don't lose aggro if already chasing/attacking
	pass

func take_damage(damage: float, is_crit: bool = false) -> void:
	if current_state == State.DEAD:
		return
	
	hp = max(0, hp - damage)
	
	# Emit damage event
	EventBus.emit_damage(damage, self, null, is_crit)
	
	# Play hit sound
	hit_sound.play()
	
	# Show damage number
	_show_damage_number(damage, is_crit)
	
	# Spawn hit particles
	_spawn_hit_particles()
	
	# Flash white briefly (visual feedback)
	_flash_damage()
	
	if hp <= 0:
		_die()

func _show_damage_number(damage: float, is_crit: bool = false) -> void:
	# Request damage number via event bus
	EventBus.damage_number_requested.emit(damage, position + Vector2(0, -size - 10), is_crit)

func _flash_damage() -> void:
	# Flash white and scale slightly
	var original_scale = visual.scale
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Flash to white
	tween.tween_property(body_shape, "modulate", Color.WHITE, 0.05)
	tween.tween_property(body_shape, "modulate", Color(1, 1, 1, 1), 0.15).set_delay(0.05)
	
	# Pulse scale slightly
	tween.tween_property(visual, "scale", original_scale * 1.15, 0.05)
	tween.tween_property(visual, "scale", original_scale, 0.15).set_delay(0.05)

func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	
	# Disable collision immediately so other arrows pass through
	$CollisionShape2D.set_deferred("disabled", true)
	$AggroRange/AggroCollision.set_deferred("disabled", true)
	$AttackRange/AttackCollision.set_deferred("disabled", true)
	
	# Play death sound
	death_sound.play()
	
	# Spawn death particles
	_spawn_death_particles()
	
	# Death animation: fade out and shrink over 0.5 seconds
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "modulate:a", 0.0, 0.5)
	tween.tween_property(visual, "scale", Vector2(0.5, 0.5), 0.5)
	
	# Give EXP to player (find player in group)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player.has_method("gain_exp"):
			player.gain_exp(exp_reward)
			print("%s killed! Player gained %.0f EXP" % [MONSTER_STATS[monster_type]["name"], exp_reward])
	
	# Emit death event
	EventBus.emit_death(self, null)
	
	# TODO: Phase 5 - drop gold
	
	# Unregister and remove after animation
	GameManager.unregister_monster(self)
	EventBus.monster_despawned.emit(self)
	await tween.finished
	queue_free()

func _spawn_hit_particles() -> void:
	# Request particles via event bus
	var world_pos = Isometric.iso_to_world(position)
	EventBus.spawn_particles("hit_particles", world_pos)

func _spawn_death_particles() -> void:
	# Request particles via event bus
	var world_pos = Isometric.iso_to_world(position)
	EventBus.spawn_particles("death_burst", world_pos)

func _exit_tree() -> void:
	GameManager.unregister_monster(self)
	if current_state != State.DEAD:
		EventBus.monster_despawned.emit(self)

func set_selected(selected: bool) -> void:
	"""Called by player to mark this as selected target (no visual indicator)"""
	is_selected = selected

func get_monster_color() -> Color:
	"""Return monster color for minimap"""
	return color
