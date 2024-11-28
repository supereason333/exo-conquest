extends Resource
class_name GameSettings

@export var select_color:Color
@export var enemy_color:Color
@export_enum("Keyboard", "Mouse", "Both") var movement_type:int
enum MOVEMENT_TYPES {keyboard, mouse, both}
@export var camera_move_speed:int
@export var camera_move_margin:int
@export var default_master:float
@export var default_sfx:float
@export var default_bgm:float
