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
	else:
		print("WARNING: HUD could not find player")

func _process(delta: float) -> void:
	# Update FPS counter
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	
	# Update player stats if player exists
	if player:
		_update_player_stats()

func _update_player_stats() -> void:
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
	attack_label.text = "ATK: %.0f" % player.attack
	defense_label.text = "DEF: %.0f" % player.defense
	speed_label.text = "Speed: %.0f" % player.MAX_SPEED
	
	# Skill info
	scatter_label.text = "Scatter Lv: %d" % player.scatter_level
	
	# Cooldown status
	if player.scatter_cooldown_timer > 0:
		cooldown_label.text = "Cooldown: %.1fs" % player.scatter_cooldown_timer
	else:
		cooldown_label.text = "Cooldown: Ready"
