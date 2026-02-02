# Conquer Game AI Agent Context

## Project Overview
- **Game**: Godot 4.6 isometric ARPG inspired by Conquer Online
- **Location**: `/home/karol/projects/conquer_game`
- **Current Architecture Grade**: B+ (improving from B-)

## Sessions Completed

### Session 1: Initial Analysis & ResourceManager ✅
- Analyzed codebase (~1,512 lines, 9 scripts)
- Created `ResourceManager` singleton to centralize asset loading
- Eliminated 11+ hardcoded `preload()`/`load()` calls
- Added graceful degradation for missing audio files

### Session 2: CombatComponent ✅
- Created reusable `CombatComponent` (106 lines)
- Features: damage variance (80%-120%), crit system, signal-based events
- Integrated into `player.gd` and `monster.gd`
- Reduced code duplication in combat logic

### Session 3: EventBus System ✅  
- Created `EventBus` singleton (25+ signals, 148 lines)
- Converted from tight coupling (`get_parent()`) to event-driven architecture
- Refactored: `player.gd`, `monster.gd`, `hud.gd`, `main.gd`
- Improved HUD performance (60fps polling → event-driven)
- **Checkpoint**: Commit `aff5d57`

### Session 4: PhysicsLayers Utility ✅
- Created `scripts/utils/physics_layers.gd` with named constants
- Eliminated magic numbers: `collision_mask = 2` → `PhysicsLayers.MONSTERS`
- Added documentation for `.tscn` collision values
- Added debug helpers: `get_layer_name()`, `decode_mask()`
- **Checkpoint**: Commit `1e1668d`

### Session 5: Configuration System 🚧 **IN PROGRESS**
**Status**: Partially completed - needs completion
**Created**:
- `scripts/config/combat_config.gd` - Combat constants & ranges
- `scripts/config/monster_stats.gd` - Individual monster stats with level scaling
- `scripts/config/monster_config.gd` - All monster types definitions
- `scripts/config/player_config.gd` - Player stats & movement config
- `scripts/autoload/config_manager.gd` - Global config access
- Added `ConfigManager` to autoload in `project.godot`

**Completed Refactoring**:
- ✅ `player.gd` - All constants replaced with config references
  - Movement: `MAX_SPEED` → `player_config.max_speed`
  - Combat: `ATTACK_RANGE` → `combat_config.attack_range`
  - Jump: `GRAVITY` → `player_config.gravity`

**Pending Work**:
- ⚠️ **INCOMPLETE**: `monster.gd` refactor (20% done)
  - Need to complete `initialize()` function rewrite
  - Replace `MONSTER_STATS` dict with `ConfigManager.get_monster_stats()`
  - Update collision range constants to use `combat_config`
- ⚠️ **PENDING**: `main.gd` refactor
  - Replace camera zoom constants
  - Update any combat range references

## Remaining Architecture Issues (Priority Order)

### High Priority
1. **Configuration System** - **CURRENT FOCUS** (Session 5 incomplete)
   - Complete monster.gd refactor (80% remaining)
   - Refactor main.gd (minor)
   - Test all game functionality

2. **Split main.gd** - Reduce 217-line monolithic class
   - Extract: `InputHandler`, `CameraController`, `DebugRenderer`

### Medium Priority  
3. **Object Pooling** - Performance optimization
   - Pool particles and projectiles
   - Reduce `instantiate()`/`queue_free()` overhead

4. **Monster Iteration Efficiency** - Per-frame `get_nodes_in_group("monsters")`
   - Cache monster list, update on spawn/despawn events

5. **Per-frame Spawning Checks** - Replace with timer-based spawning

### Low Priority
6. **Documentation** - Complex algorithms (spawning, targeting) undocumented
7. **Inconsistent Naming** - Mix of `snake_case` vs `SCREAMING_SNAKE_CASE`
8. **Component Extraction** - `movement_component`, `health_component`, `skill_component`

## Technical Context

### Autoload Order (Critical!)
1. `EventBus` - First
2. `ResourceManager` - Second  
3. **`ConfigManager` - Third** (newly added)
4. `GameManager` - Fourth

### Key Patterns
- **Event-driven**: All systems communicate via `EventBus` signals
- **Resource loading**: Always use `ResourceManager.get_scene()`/`get_sound()`
- **Combat logic**: Always use `CombatComponent` for damage calculation
- **Physics layers**: Use `PhysicsLayers.MONSTERS` (no magic numbers)
- **Configuration**: Use `ConfigManager.get_*_config()` (replacing hardcoding)

### Testing Commands
```bash
# Check script errors
godot --headless --check-only

# Find remaining magic numbers (should be none)
grep -rn "collision_mask = [0-9]" scenes/ scripts/

# Find hardcoded asset paths (should be none)  
grep -r "preload\|load(" scenes/ scripts/ | grep -v ResourceManager

# Check lines in large files
wc -l scenes/player/player.gd scenes/monsters/monster.gd scenes/main.gd
```

### Current Grade Trajectory
- **Start**: C+ (tight coupling, magic numbers)
- **After Session 3**: B- (EventBus + clean architecture)
- **After Session 4**: B+ (No magic numbers, self-documenting)
- **Target**: A- (production-ready architecture)

## Next Session Action Plan

**Priority 1**: Complete Session 5 Configuration System
1. Complete `monster.gd` refactor (80% remaining):
   - Update `initialize()` function to use `ConfigManager.get_monster_stats()`
   - Replace `AGGRO_RANGE`, `ATTACK_RANGE`, `RETURN_DISTANCE`, `WANDER_*` with `combat_config` values
   - Update collision setup to use config values
2. Refactor `main.gd` (minor): Replace any remaining constants
3. Test game functionality thoroughly
4. Create git checkpoint for Session 5 completion

**Priority 2**: Split main.gd (Session 6)
- Extract input handling, camera control, debug rendering
- Reduce complexity and improve single responsibility

**Testing Checklist for Session 5**
- [ ] Player movement, jumping, and combat work correctly
- [ ] Monster AI, spawning, and scaling work correctly  
- [ ] All constants replaced with config references
- [ ] Game balance unchanged (same attack ranges, speeds, etc.)
- [ ] No script errors or warnings

## Quick Reference for Next Agent

### Files Created This Session
- `scripts/config/combat_config.gd`
- `scripts/config/monster_stats.gd` 
- `scripts/config/monster_config.gd`
- `scripts/config/player_config.gd`
- `scripts/autoload/config_manager.gd`

### Files Modified This Session
- `project.godot` - Added ConfigManager autoload
- `scenes/player/player.gd` - Complete refactor to use configs
- `scenes/monsters/monster.gd` - Partial refactor (20% done)

### Key Code Patterns to Follow
```gdscript
# Get configs in _ready()
player_config = ConfigManager.get_player_config()
combat_config = ConfigManager.get_combat_config()

# Use config values instead of constants
if distance > combat_config.attack_range:
    # Do something

# Monster stats access
var stats = ConfigManager.get_monster_stats(monster_type)
hp = stats.get_hp_at_level(level)
```

**Continue from monster.gd refactor where left off**