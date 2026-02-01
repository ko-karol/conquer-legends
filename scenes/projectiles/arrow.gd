extends Area2D

# Projectile arrow for normal attacks
# Flies toward target and deals collision-based damage

var damage: float = 0.0
var is_crit: bool = false
var speed: float = 600.0
var direction: Vector2 = Vector2.RIGHT
var max_distance: float = 400.0
var distance_traveled: float = 0.0
var is_visual_only: bool = false  # For scatter skill visual arrows
var target_position: Vector2 = Vector2.ZERO  # For visual arrows to stop at target

@onready var visual: Node2D = $Visual
@onready var arrow_shape: Polygon2D = $Visual/ArrowShape

func _ready() -> void:
	# Setup collision
	var collision = $CollisionShape2D
	var capsule = CapsuleShape2D.new()
	capsule.radius = 3.0
	capsule.height = 12.0
	collision.shape = capsule
	
	# Setup arrow visual (small triangle)
	arrow_shape.polygon = PackedVector2Array([
		Vector2(8, 0),    # Tip
		Vector2(-4, -3),  # Back left
		Vector2(-4, 3)    # Back right
	])
	
	# Rotate visual to match direction
	visual.rotation = direction.angle()
	
	# Connect collision signal (only for real arrows, not visual)
	if not is_visual_only:
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# For visual arrows with target position, check if reached target
	if is_visual_only and target_position != Vector2.ZERO:
		var to_target = target_position - position
		if to_target.length() < speed * delta:
			# Reached target, remove arrow
			queue_free()
			return
	
	# Move arrow
	var movement = direction * speed * delta
	position += movement
	distance_traveled += movement.length()
	
	# Remove if traveled too far
	if distance_traveled >= max_distance:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if is_visual_only:
		return
	
	# Check if it's a monster
	if body.has_method("take_damage"):
		body.take_damage(damage, is_crit)
		queue_free()

func setup(start_pos: Vector2, target_dir: Vector2, dmg: float, visual_only: bool = false, target_pos: Vector2 = Vector2.ZERO, crit: bool = false) -> void:
	position = start_pos
	direction = target_dir.normalized()
	damage = dmg
	is_crit = crit
	is_visual_only = visual_only
	target_position = target_pos
	visual.rotation = direction.angle()
