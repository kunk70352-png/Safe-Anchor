## LevelData — Custom Resource that defines all parameters for a single level.
## Create .tres files in resources/levels/ to define each level.
## Equivalent to Unity's ScriptableObject or Unreal's DataTable.
class_name LevelData
extends Resource

# ---- Level Identity ----
@export var level_number: int = 1
@export var level_name: String = "Level 1"

# ---- Win/Lose Conditions ----
@export var target_rescued: int = 5          # How many refugees must reach safe house
@export var time_limit: float = 60.0         # Countdown in seconds

# ---- Refugee Configuration ----
@export var refugee_count: int = 8           # Refugees to spawn at level start
@export var refugee_wander_speed: float = 60.0
@export var refugee_seek_speed: float = 100.0
@export var refugee_wander_interval: float = 2.0  # Seconds between direction changes
@export var refugee_spawn_positions: Array[Vector2] = []  # Spawn locations

# ---- Anchor Configuration ----
@export var anchor_limit: int = 3            # Max anchors player can place
@export var anchor_attraction_radius: float = 150.0

# ---- Safe House Configuration ----
@export var safe_house_position: Vector2 = Vector2(640, 360)  # Center of 1280x720
@export var safe_house_attraction_radius: float = 200.0

# ---- Extension Points (for future use) ----
@export var anchor_type: String = "default"  # For anchor subclass selection later
@export var difficulty_modifier: float = 1.0 # Global difficulty multiplier
@export var tile_map_scene: PackedStringArray = []  # Custom map scenes
