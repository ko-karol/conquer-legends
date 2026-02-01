extends Node2D

# Floating damage number that animates upward and fades

var damage_value: float = 0.0
var is_crit: bool = false
var lifetime: float = 1.0
var elapsed: float = 0.0
var rise_speed: float = 50.0

@onready var label: Label = $Label

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	elapsed += delta
	
	# Rise upward
	position.y -= rise_speed * delta
	
	# Fade out
	var alpha = 1.0 - (elapsed / lifetime)
	modulate.a = alpha
	
	# Remove when done
	if elapsed >= lifetime:
		queue_free()

func setup(dmg: float, crit: bool = false) -> void:
	damage_value = dmg
	is_crit = crit
	
	# Update label text
	if label:
		label.text = str(int(damage_value))
		
		# Apply crit styling
		if is_crit:
			label.add_theme_font_size_override("font_size", 24)
			label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			label.add_theme_color_override("font_color", Color.WHITE)
