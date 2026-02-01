extends CanvasLayer

# HUD overlay with HP/MP/EXP bars, stats, and controls

# References to UI elements
@onready var hp_bar: ProgressBar = $MarginContainer/Panel/InnerMargin/VBoxContainer/HPBar/ProgressBar
@onready var hp_label: Label = $MarginContainer/Panel/InnerMargin/VBoxContainer/HPBar/ValueLabel
@onready var mp_bar: ProgressBar = $MarginContainer/Panel/InnerMargin/VBoxContainer/MPBar/ProgressBar
@onready var mp_label: Label = $MarginContainer/Panel/InnerMargin/VBoxContainer/MPBar/ValueLabel
@onready var exp_bar: ProgressBar = $MarginContainer/Panel/InnerMargin/VBoxContainer/EXPBar/ProgressBar
@onready var exp_label: Label = $MarginContainer/Panel/InnerMargin/VBoxContainer/EXPBar/ValueLabel

@onready var level_label: Label = $MarginContainer/Panel/InnerMargin/VBoxContainer/StatsContainer/LevelLabel
@onready var attack_label: Label = $MarginContainer/Panel/InnerMargin/VBoxContainer/StatsContainer/AttackLabel
@onready var defense_label: Label = $MarginContainer/Panel/InnerMargin/VBoxContainer/StatsContainer/DefenseLabel
@onready var speed_label: Label = $MarginContainer/Panel/InnerMargin/VBoxContainer/StatsContainer/SpeedLabel

@onready var scatter_label: Label = $MarginContainer/Panel/InnerMargin/VBoxContainer/SkillInfo/ScatterLabel
@onready var cooldown_label: Label = $MarginContainer/Panel/InnerMargin/VBoxContainer/SkillInfo/CooldownLabel

@onready var fps_label: Label = $MarginContainer/Panel/InnerMargin/VBoxContainer/FPSLabel

var player: CharacterBody2D = null

func _ready() -> void:
	# Find player in scene
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		print("HUD connected to player")
		# Do initial update
		_update_player_stats()
	else:
		print("WARNING: HUD could not find player")
	
	# Connect to event bus signals
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_mp_changed.connect(_on_player_mp_changed)
	EventBus.player_stats_changed.connect(_on_player_stats_changed)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)
	EventBus.player_gained_exp.connect(_on_player_exp_gained)
	EventBus.skill_cooldown_changed.connect(_on_skill_cooldown_changed)

func _process(_delta: float) -> void:
	# Update FPS counter
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	
	# Update scatter level (changes based on player level)
	if player:
		scatter_label.text = "Scatter Lv: %d" % player.scatter_level

func _update_player_stats() -> void:
	if not player:
		return
	
	# HP bar
	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp
	hp_label.text = "%d/%d" % [player.hp, player.max_hp]
	
	# MP bar
	mp_bar.max_value = player.max_mp
	mp_bar.value = player.mp
	mp_label.text = "%d/%d" % [player.mp, player.max_mp]
	
	# EXP bar
	exp_bar.max_value = player.exp_to_next
	exp_bar.value = player.exp
	exp_label.text = "%d/%d" % [player.exp, player.exp_to_next]
	
	# Stats
	level_label.text = "Level: %d" % player.level
	attack_label.text = "ATK: %.0f" % player.combat.get_attack()
	defense_label.text = "DEF: %.0f" % player.combat.get_defense()
	speed_label.text = "Speed: %.0f" % player.MAX_SPEED
	
	# Skill info
	scatter_label.text = "Scatter Lv: %d" % player.scatter_level
	
	# Cooldown status
	if player.scatter_cooldown_timer > 0:
		cooldown_label.text = "Cooldown: %.1fs" % player.scatter_cooldown_timer
	else:
		cooldown_label.text = "Cooldown: Ready"

# Event handlers - called when stats change via EventBus

func _on_player_hp_changed(current_hp: float, max_hp_val: float) -> void:
	hp_bar.max_value = max_hp_val
	hp_bar.value = current_hp
	hp_label.text = "%d/%d" % [current_hp, max_hp_val]

func _on_player_mp_changed(current_mp: float, max_mp_val: float) -> void:
	mp_bar.max_value = max_mp_val
	mp_bar.value = current_mp
	mp_label.text = "%d/%d" % [current_mp, max_mp_val]

func _on_player_stats_changed(_player_ref: Node) -> void:
	# Full stats refresh (level up, etc.)
	_update_player_stats()

func _on_player_leveled_up(new_level: int) -> void:
	level_label.text = "Level: %d" % new_level
	_update_player_stats()

func _on_player_exp_gained(_exp_amount: float) -> void:
	if player:
		exp_bar.max_value = player.exp_to_next
		exp_bar.value = player.exp
		exp_label.text = "%d/%d" % [player.exp, player.exp_to_next]

func _on_skill_cooldown_changed(skill_name: String, cooldown_remaining: float) -> void:
	if skill_name == "scatter":
		if cooldown_remaining > 0:
			cooldown_label.text = "Cooldown: %.1fs" % cooldown_remaining
		else:
			cooldown_label.text = "Cooldown: Ready"
