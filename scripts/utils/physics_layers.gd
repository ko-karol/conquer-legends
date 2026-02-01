## PhysicsLayers Utility Class
##
## Provides named constants for physics collision layers to avoid magic numbers.
## Corresponds to layer names defined in project.godot [layer_names] section.
##
## Layer assignments (as configured in project.godot):
##   Layer 1 (bit 0): player
##   Layer 2 (bit 1): monsters  
##   Layer 3 (bit 2): projectiles
##   Layer 4 (bit 3): environment
##
## Usage Examples:
##   # Single layer
##   query.collision_mask = PhysicsLayers.MONSTERS
##   
##   # Multiple layers (use bitwise OR)
##   body.collision_mask = PhysicsLayers.PLAYER | PhysicsLayers.ENVIRONMENT
##   
##   # Check if layer is set
##   if collision_mask & PhysicsLayers.MONSTERS:
##       print("Collides with monsters")
##
## Note: .tscn files use decimal values for collision_mask:
##   - 13 (binary 1101) = PLAYER + MONSTERS + ENVIRONMENT
##   - 14 (binary 1110) = MONSTERS + PROJECTILES + ENVIRONMENT
##   - Use this class when setting masks in GDScript code

class_name PhysicsLayers

## Layer bit values (power of 2)
const PLAYER: int = 1        # 2^0 = 1  (Layer 1)
const MONSTERS: int = 2      # 2^1 = 2  (Layer 2)
const PROJECTILES: int = 4   # 2^2 = 4  (Layer 3)
const ENVIRONMENT: int = 8   # 2^3 = 8  (Layer 4)

## Common mask combinations for convenience
const MASK_ALL: int = 15                                    # All layers (1111 binary)
const MASK_ENTITIES: int = PLAYER | MONSTERS                # Living entities only
const MASK_COMBAT: int = PLAYER | MONSTERS | PROJECTILES    # Combat-related layers
const MASK_SOLID: int = PLAYER | MONSTERS | ENVIRONMENT     # Physical obstacles

## Helper function to get layer name for debugging
static func get_layer_name(layer_bit: int) -> String:
	match layer_bit:
		PLAYER:
			return "player"
		MONSTERS:
			return "monsters"
		PROJECTILES:
			return "projectiles"
		ENVIRONMENT:
			return "environment"
		_:
			return "unknown"

## Helper function to decode mask into layer names
static func decode_mask(mask: int) -> Array[String]:
	var layers: Array[String] = []
	if mask & PLAYER:
		layers.append("player")
	if mask & MONSTERS:
		layers.append("monsters")
	if mask & PROJECTILES:
		layers.append("projectiles")
	if mask & ENVIRONMENT:
		layers.append("environment")
	return layers
