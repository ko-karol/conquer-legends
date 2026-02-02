extends CanvasLayer

# XP bar at bottom of screen showing experience progress

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $ProgressBar/Label

var player: CharacterBody2D = null

func _ready() -> void:
	# Find player in scene
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		_update_xp()
	else:
		push_warning("XPBar could not find player")
	
	# Connect to EventBus signals
	EventBus.player_gained_exp.connect(_on_player_gained_exp)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)

func _update_xp() -> void:
	if not player:
		return
	
	var xp_percent = (float(player.exp) / float(player.exp_to_next)) * 100.0
	progress_bar.value = xp_percent
	label.text = "%.3f%%" % xp_percent

# EventBus Signal Handlers

func _on_player_gained_exp(_exp_amount: float) -> void:
	_update_xp()

func _on_player_leveled_up(_new_level: int) -> void:
	_update_xp()
