extends Sprite2D

# Tiled isometric floor background

func _ready() -> void:
	# Set material with shader
	var shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://scenes/floor/floor.gdshader")
	
	# Configure shader uniforms
	shader_material.set_shader_parameter("grid_size", Vector2(100, 100))
	shader_material.set_shader_parameter("grid_color", Color(0.25, 0.35, 0.25))
	shader_material.set_shader_parameter("tile_color_1", Color(0.15, 0.22, 0.15))
	shader_material.set_shader_parameter("tile_color_2", Color(0.18, 0.25, 0.18))
	shader_material.set_shader_parameter("grid_thickness", 2.0)
	
	material = shader_material
	
	# Create a large texture to cover the world
	var img = Image.create(2048, 2048, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	# texture = ImageTexture.create_from_image(img)
	
	# Center and scale to cover world
	centered = true
	scale = Vector2(20, 20)
	z_index = -100
