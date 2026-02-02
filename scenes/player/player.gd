extends CharacterBody2D

## Player character with click-to-move, jump, and combat
## Based on Pygame implementation (GODOT_MIGRATION_CONTEXT.md)
##
## Physics Layers (configured in player.tscn):
##   collision_layer = 1 (PhysicsLayers.PLAYER)
##   collision_mask = 14 (binary 1110 = MONSTERS | PROJECTILES | ENVIRONMENT)

# Configuration references
var player_config: PlayerConfig
var combat_config: CombatConfig

# Player stats (initialized from config)
@export var level: int = 1
var max_hp: float
var hp: float
var max_mp: float
var mp: float
var exp: float = 0.0
var exp_to_next: float

# Combat component handles attack, defense, damage calculation
var combat: CombatComponent = null

# Skill state
var scatter_level: int = 10
var scatter_cooldown_timer: float = 0.0
var auto_attack_timer: float = 0.0

# Target selection (Conquer Online style)
var selected_target: Node2D = null

# Note: All resources now loaded via ResourceManager singleton

# Movement state
enum State { IDLE, MOVING, JUMPING, ATTACKING }
var current_state: State = State.IDLE

var target_pos: Vector2 = Vector2.ZERO
var move_direction: Vector2 = Vector2.ZERO
var current_speed: float = 0.0
var facing_angle: float = 0.0

# Jump state
var is_jumping: bool = false
var jump_start_pos: Vector2 = Vector2.ZERO
var jump_target_pos: Vector2 = Vector2.ZERO
var jump_horizontal_velocity: Vector2 = Vector2.ZERO
var jump_vz: float = 0.0  # Vertical velocity (Z-axis)
var jump_z: float = 0.0   # Current Z height

# Input queue
var queued_action: Dictionary = {}

# Visual elements
@onready var visual: Node2D = $Visual
@onready var body_shape: Polygon2D = $Visual/Body
@onready var weapon_shape: Polygon2D = $Visual/Weapon
@onready var shadow_shape: Polygon2D = $Visual/Shadow

# Audio
@onready var attack_sound: AudioStreamPlayer = $AttackSound
@onready var levelup_sound: AudioStreamPlayer = $LevelUpSound

func _ready() -> void:
	# Load configurations
	player_config = ConfigManager.get_player_config()
	combat_config = ConfigManager.get_combat_config()
	
	# Initialize stats from config
	level = player_config.starting_level
	max_hp = player_config.starting_hp
	hp = max_hp
	max_mp = player_config.starting_mp
	mp = max_mp
	exp_to_next = player_config.starting_exp_to_next
	
	# Initialize combat component with config values
	combat = CombatComponent.new(self)
	combat.setup(player_config.starting_atk, player_config.starting_def, 0.15, 1.5)
	add_child(combat)
	
	# Load sound effects from ResourceManager
	attack_sound.stream = ResourceManager.get_sound("arrow_shoot")
	levelup_sound.stream = ResourceManager.get_sound("levelup")
	
	# Start at world center
	position = Isometric.world_to_iso(GameManager.WORLD_CENTER)
	
	print("Player spawned at world position: %s" % GameManager.WORLD_CENTER)



func _physics_process(delta: float) -> void:
	# Update scatter level based on player level (every 5 levels)
	scatter_level = level / 5
	
	# Regen HP/MP
	var old_hp = hp
	var old_mp = mp
	hp = min(hp + player_config.hp_regen * delta, max_hp)
	mp = min(mp + player_config.mp_regen * delta, max_mp)
	
	# Emit events if values changed significantly (every 1 HP/MP to avoid spam)
	if floor(hp) != floor(old_hp):
		EventBus.player_hp_changed.emit(hp, max_hp)
	if floor(mp) != floor(old_mp):
		EventBus.player_mp_changed.emit(mp, max_mp)
	
	# Update cooldowns
	if scatter_cooldown_timer > 0:
		scatter_cooldown_timer -= delta
	if auto_attack_timer > 0:
		auto_attack_timer -= delta
	
	# Auto-attack selected target
	_process_auto_attack(delta)
	
	# Update state machine
	match current_state:
		State.IDLE:
			_physics_idle(delta)
		State.MOVING:
			_physics_moving(delta)
		State.JUMPING:
			_physics_jumping(delta)
		State.ATTACKING:
			_physics_attacking(delta)
	
	# Update facing direction visual
	_update_facing_visual()

func _physics_idle(delta: float) -> void:
	# Decelerate to stop
	if current_speed > 0:
		current_speed = max(0, current_speed - player_config.deceleration * delta)
		velocity = move_direction * current_speed
		move_and_slide()

func _physics_moving(delta: float) -> void:
	# Calculate distance to target
	var to_target = target_pos - position
	var distance = to_target.length()
	
	# Check if reached target
	if distance < player_config.stop_threshold:
		current_state = State.IDLE
		current_speed = 0
		velocity = Vector2.ZERO
		_process_queued_action()
		return
	
	# Update direction
	move_direction = to_target.normalized()
	facing_angle = move_direction.angle()
	
	# Calculate speed based on distance (decelerate near target)
	if distance < player_config.decel_distance:
		# Ease out
		var target_speed = (distance / player_config.decel_distance) * player_config.max_speed
		if current_speed > target_speed:
			current_speed = max(target_speed, current_speed - player_config.deceleration * delta)
		else:
			current_speed = min(target_speed, current_speed + player_config.acceleration * delta)
	else:
		# Accelerate to max speed
		current_speed = min(player_config.max_speed, current_speed + player_config.acceleration * delta)
	
	# Apply movement
	velocity = move_direction * current_speed
	move_and_slide()

func _physics_jumping(delta: float) -> void:
	# Update jump physics (vertical)
	jump_vz -= player_config.gravity * delta
	jump_z += jump_vz * delta
	
	# Horizontal movement
	velocity = jump_horizontal_velocity
	move_and_slide()
	
	# Check if landed
	if jump_z <= 0:
		jump_z = 0
		is_jumping = false
		current_state = State.IDLE
		
		# Re-enable collision with monsters when landing
		collision_mask = PhysicsLayers.MONSTERS | PhysicsLayers.PROJECTILES | PhysicsLayers.ENVIRONMENT
		
		_process_queued_action()
	
	# Update visual Y offset for jump height
	visual.position.y = -jump_z

func _physics_attacking(delta: float) -> void:
	# Placeholder for attack state (Phase 5)
	pass

func _update_facing_visual() -> void:
	# Rotate weapon to face direction
	weapon_shape.rotation = facing_angle

func move_to(world_target: Vector2) -> void:
	# Queue move if busy, otherwise execute
	if current_state == State.JUMPING or current_state == State.ATTACKING:
		queued_action = {"type": "move", "target": world_target}
		return
	
	var iso_target = Isometric.world_to_iso(world_target)
	target_pos = iso_target
	current_state = State.MOVING
	print("Moving to world pos: %s (iso: %s)" % [world_target, iso_target])

func jump_to(world_target: Vector2) -> void:
	# Queue jump if busy, otherwise execute
	if current_state == State.JUMPING or current_state == State.ATTACKING:
		queued_action = {"type": "jump", "target": world_target}
		return
	
	var iso_target = Isometric.world_to_iso(world_target)
	var jump_distance = position.distance_to(iso_target)
	
	# Limit jump distance
	if jump_distance > player_config.jump_max_distance:
		var direction = (iso_target - position).normalized()
		iso_target = position + direction * player_config.jump_max_distance
	
	# Calculate jump parameters
	jump_start_pos = position
	jump_target_pos = iso_target
	jump_vz = player_config.jump_initial_vz
	jump_z = 0
	
	# Calculate horizontal velocity to reach target during jump arc
	var jump_time = 2.0 * player_config.jump_initial_vz / player_config.gravity
	jump_horizontal_velocity = (jump_target_pos - jump_start_pos) / jump_time
	
	# Disable collision with monsters while jumping (jump over them)
	collision_mask = PhysicsLayers.ENVIRONMENT
	
	is_jumping = true
	current_state = State.JUMPING
	facing_angle = jump_horizontal_velocity.angle()
	
	print("Jumping to world pos (distance: %.1f)" % jump_distance)

func _process_queued_action() -> void:
	if queued_action.is_empty():
		return
	
	var action = queued_action
	queued_action = {}
	
	match action["type"]:
		"move":
			move_to(action["target"])
		"jump":
			jump_to(action["target"])

func take_damage(damage: float) -> void:
	var actual_damage = combat.apply_damage(damage, false)
	hp = max(0, hp - actual_damage)
	
	# Emit damage event
	EventBus.emit_damage(actual_damage, self, null, false)
	EventBus.player_hp_changed.emit(hp, max_hp)
	
	# Flash damage effect
	_flash_damage()
	
	# Request screen shake via event bus
	EventBus.shake_camera(5.0)
	
	print("Player took %.0f damage (HP: %.0f/%.0f)" % [actual_damage, hp, max_hp])

func _flash_damage() -> void:
	# Flash red and pulse
	var original_scale = visual.scale
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Flash to red
	tween.tween_property(body_shape, "modulate", Color(1, 0.3, 0.3, 1), 0.05)
	tween.tween_property(body_shape, "modulate", Color(1, 1, 1, 1), 0.15).set_delay(0.05)
	
	# Pulse scale slightly
	tween.tween_property(visual, "scale", original_scale * 1.1, 0.05)
	tween.tween_property(visual, "scale", original_scale, 0.15).set_delay(0.05)

func gain_exp(amount: float) -> void:
	exp += amount
	EventBus.player_gained_exp.emit(amount)
	while exp >= exp_to_next:
		_level_up()

func _level_up() -> void:
	level += 1
	exp -= exp_to_next
	exp_to_next = 100 * pow(1.15, level - 1)
	
	# Increase stats (lines 73-74)
	combat.increase_attack(8)
	combat.increase_defense(3)
	max_hp += 50
	max_mp += 30
	hp = max_hp
	mp = max_mp
	
	print("LEVEL UP! Now level %d" % level)
	
	# Emit level up event
	EventBus.player_leveled_up.emit(level)
	
	# Play level up sound
	levelup_sound.play()
	
	# Spawn level-up particles
	_spawn_levelup_particles()

func _spawn_levelup_particles() -> void:
	# Request particles via event bus
	var world_pos = Isometric.iso_to_world(position)
	EventBus.spawn_particles("levelup_burst", world_pos)

func normal_attack(target_monster: Node2D) -> void:
	if not is_instance_valid(target_monster):
		return
	
	# Check range
	var distance = position.distance_to(target_monster.position)
	if distance > combat_config.attack_range:
		print("Target out of range")
		return
	
	# Calculate damage with min-max and crit using combat component
	var damage_result = combat.calculate_damage()
	var final_damage = damage_result["damage"]
	var is_crit = damage_result["is_crit"]
	
	# Calculate direction
	var direction = (target_monster.position - position).normalized()
	
	# Update facing
	facing_angle = direction.angle()
	
	# Play attack sound
	attack_sound.play()
	
	# Spawn muzzle flash
	_spawn_muzzle_flash()
	
	# Fire arrow projectile
	var arrow = ResourceManager.instantiate_scene("arrow")
	if arrow:
		get_parent().add_child(arrow)
		arrow.setup(position, direction, final_damage, false, Vector2.ZERO, is_crit)
	
	var crit_text = " CRIT!" if is_crit else ""
	print("Normal attack: %.0f damage%s" % [final_damage, crit_text])

func _spawn_muzzle_flash() -> void:
	# Request particles via event bus
	var world_pos = Isometric.iso_to_world(position)
	EventBus.spawn_particles("muzzle_flash", world_pos)

func scatter_skill(world_target: Vector2) -> void:
	# Check cooldown
	if scatter_cooldown_timer > 0:
		print("Scatter on cooldown (%.1fs)" % scatter_cooldown_timer)
		return
	
	# Check MP
	if mp < combat_config.scatter_mp_cost:
		print("Not enough MP")
		return
	
	# Consume MP and start cooldown
	mp -= combat_config.scatter_mp_cost
	scatter_cooldown_timer = combat_config.scatter_cooldown
	
	# Emit MP change and cooldown events
	EventBus.player_mp_changed.emit(mp, max_mp)
	EventBus.skill_cooldown_changed.emit("scatter", scatter_cooldown_timer)
	
	# Calculate scatter parameters (from context lines 119-126)
	var num_arrows = 355 + scatter_level
	var spread_angle = 0.8 + scatter_level * 0.1
	var scatter_damage = combat.get_attack() * (0.8 + scatter_level * 0.1)
	
	# Direction to target (center of fan)
	var iso_target = Isometric.world_to_iso(world_target)
	var base_direction = (iso_target - position).normalized()
	var base_angle = base_direction.angle()
	
	# Update facing
	facing_angle = base_angle
	
	# Play attack sound
	attack_sound.play()
	
	# Spawn muzzle flash for scatter
	_spawn_muzzle_flash()
	
	# Find all monsters within the fan cone (use cached list from GameManager)
	var monsters = GameManager.active_monsters
	var valid_targets = []
	
	for monster in monsters:
		if not is_instance_valid(monster):
			continue
		
		var to_monster = monster.position - position
		var distance = to_monster.length()
		
		# Check range
		if distance > combat_config.scatter_range:
			continue
		
		# Check if within fan angle
		var monster_angle = to_monster.angle()
		var angle_diff = abs(fmod(monster_angle - base_angle + PI, TAU) - PI)
		
		if angle_diff <= spread_angle / 2.0:
			valid_targets.append(monster)
	
	# Sort by distance (closer first)
	valid_targets.sort_custom(func(a, b): return position.distance_to(a.position) < position.distance_to(b.position))
	
	# Hit exactly num_arrows unique monsters (1 arrow per monster)
	var hit_count = min(num_arrows, valid_targets.size())
	var hit_monsters = []
	var total_damage = 0.0
	var crit_count = 0
	
	for i in range(hit_count):
		var monster = valid_targets[i]
		hit_monsters.append(monster)
		
		# Calculate damage with min-max and crit for each arrow using combat component
		var damage_result = combat.calculate_damage(scatter_damage)
		var final_damage = damage_result["damage"]
		var is_crit = damage_result["is_crit"]
		
		if is_crit:
			crit_count += 1
		total_damage += final_damage
		
		# Apply instant hitscan damage
		monster.take_damage(final_damage, is_crit)
		
		# Spawn ONE visual arrow flying directly toward THIS monster
		var visual_arrow = ResourceManager.instantiate_scene("arrow")
		if visual_arrow:
			get_parent().add_child(visual_arrow)
			var direction_to_monster = (monster.position - position).normalized()
			visual_arrow.setup(position, direction_to_monster, 0, true, monster.position)  # visual_only = true, stops at monster
	
	var avg_damage = total_damage / hit_count if hit_count > 0 else 0
	var crit_text = " (%d crits)" % crit_count if crit_count > 0 else ""
	print("Scatter: %d arrows at %d monsters, avg %.0f damage%s" % [hit_count, hit_monsters.size(), avg_damage, crit_text])
	
	# Emit scatter used event
	EventBus.player_scatter_used.emit(hit_count, total_damage)

# Target selection functions (Conquer Online style)
func select_target(target: Node2D) -> void:
	# Clear previous target's selection
	if is_instance_valid(selected_target) and selected_target.has_method("set_selected"):
		selected_target.set_selected(false)
	
	# Set new target
	selected_target = target
	
	# Show selection on target
	if is_instance_valid(selected_target) and selected_target.has_method("set_selected"):
		selected_target.set_selected(true)
	
	# Emit target change event
	EventBus.player_target_changed.emit(target)
	
	print("Target selected: %s" % (target.name if is_instance_valid(target) else "None"))

func clear_target() -> void:
	if is_instance_valid(selected_target) and selected_target.has_method("set_selected"):
		selected_target.set_selected(false)
	selected_target = null
	
	# Emit target cleared event
	EventBus.player_target_changed.emit(null)
	
	print("Target cleared")

func _process_auto_attack(delta: float) -> void:
	# Check if we have a valid target
	if not is_instance_valid(selected_target):
		if selected_target != null:
			selected_target = null
		return
	
	# Don't auto-attack while jumping or attacking manually
	if current_state == State.JUMPING:
		return
	
	# Check if cooldown ready
	if auto_attack_timer > 0:
		return
	
	# Check range
	var distance = position.distance_to(selected_target.position)
	if distance > combat_config.attack_range:
		# Target too far, could optionally move closer here
		return
	
	# Auto-attack!
	_execute_attack(selected_target)
	auto_attack_timer = combat_config.auto_attack_cooldown

func _execute_attack(target_monster: Node2D) -> void:
	"""Execute attack on target (shared by manual and auto-attack)"""
	if not is_instance_valid(target_monster):
		return
	
	# Calculate direction
	var direction = (target_monster.position - position).normalized()
	
	# Update facing
	facing_angle = direction.angle()
	
	# Play attack sound
	attack_sound.play()
	
	# Spawn muzzle flash
	_spawn_muzzle_flash()
	
	# Fire arrow projectile
	var arrow = ResourceManager.instantiate_scene("arrow")
	if arrow:
		get_parent().add_child(arrow)
		arrow.setup(position, direction, combat.get_attack(), false)
