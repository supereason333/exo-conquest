extends Sprite2D
class_name UnitSprite

signal anim_finished

@export var color_texture:CompressedTexture2D
@export var animations:Array[UnitSpriteAnimation]
@export var default_anim:StringName

var current_animation_index:int:
	set(value):
		value = clamp(value, 0, animations.size() - 1)
		current_animation_index = value
var current_visual_rotation_frame:int:
	set(value):
		value = clamp(value, 0, vframes - 1)
		frame_coords.y = value
		current_visual_rotation_frame = value
var playing := false
var animation_frame_index:int = 0
var color:Color

@onready var color_sprite := $ColorSprite
@onready var anim_timer := $AnimTimer

func _ready() -> void:
	color_sprite.hframes = hframes
	color_sprite.vframes = vframes
	if default_anim:
		play_anim(default_anim)

func set_visual_rotation(rot:float):
	current_visual_rotation_frame = get_sprite_frame_from_rotation(rot)

func play_anim(anim_name:StringName):
	for i in animations.size():
		if animations[i].animation_name == anim_name:
			current_animation_index = i
			playing = true
			if !anim_timer.is_stopped():
				anim_timer.stop()
			anim_timer.wait_time = animations[i].speed
			
			anim_timer.start()
			_on_anim_timer_timeout()
			return

func stop_animation():
	if !anim_timer.is_stopped():
		anim_timer.stop()


func get_sprite_frame_from_rotation(rotation:float) -> float:
	return snapped((rotation + PI) / TAU * vframes, 1)

func _on_frame_changed() -> void:
	color_sprite.frame = frame

func _on_anim_timer_timeout() -> void:
	if animation_frame_index >= animations[current_animation_index].frames.size():
		animation_frame_index = 0
	frame_coords.x = animations[current_animation_index].frames[animation_frame_index]
	
	animation_frame_index += 1
	if animation_frame_index >= animations[current_animation_index].frames.size():
		emit_signal("anim_finished")
		if animations[current_animation_index].one_shot:
			anim_timer.stop()
		animation_frame_index = 0
