extends Resource
class_name PlayerConfig

## Player-specific configuration for stats, movement, and progression
## Centralizes all player constants to avoid hardcoding values

# Starting stats
@export var starting_level: int = 1
@export var starting_hp: float = 500.0
@export var starting_mp: float = 300.0
@export var starting_atk: float = 20.0
@export var starting_def: float = 10.0
@export var starting_exp_to_next: float = 100.0

# Movement constants
@export var max_speed: float = 200.0
@export var acceleration: float = 1500.0
@export var deceleration: float = 2000.0
@export var decel_distance: float = 150.0  ## Distance to start decelerating
@export var stop_threshold: float = 5.0  ## Distance to consider "arrived"

# Jump mechanics
@export var jump_initial_vz: float = 350.0  ## Initial vertical velocity
@export var gravity: float = 800.0  ## Gravity applied while jumping
@export var jump_max_distance: float = 300.0  ## Maximum jump distance

# Regeneration rates (per second)
@export var hp_regen: float = 1.0
@export var mp_regen: float = 5.0

# Combat (using CombatConfig for shared values)
## Note: Attack ranges and cooldowns are in CombatConfig

## Creates a default player configuration
static func create_default() -> PlayerConfig:
	var config = PlayerConfig.new()
	config.starting_level = 1
	config.starting_hp = 500.0
	config.starting_mp = 300.0
	config.starting_atk = 20.0
	config.starting_def = 10.0
	config.starting_exp_to_next = 100.0
	config.max_speed = 200.0
	config.acceleration = 1500.0
	config.deceleration = 2000.0
	config.decel_distance = 150.0
	config.stop_threshold = 5.0
	config.jump_initial_vz = 350.0
	config.gravity = 800.0
	config.jump_max_distance = 300.0
	config.hp_regen = 1.0
	config.mp_regen = 5.0
	return config
