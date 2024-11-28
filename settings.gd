extends Control

var settings_changed := false
var temp_settings:GameSettings

@onready var save_popup := $Window
@onready var camera_options := $MarginContainer/VBoxContainer/TabContainer/Game/HBoxContainer/LeftBox/CameraControlOptions
@onready var camera_speed := $MarginContainer/VBoxContainer/TabContainer/Game/HBoxContainer/LeftBox/CameraSpeedSlider
@onready var selection_color_picker := $MarginContainer/VBoxContainer/TabContainer/Game/HBoxContainer/LeftBox/SelectionColor
@onready var enemy_color_picker := $MarginContainer/VBoxContainer/TabContainer/Game/HBoxContainer/LeftBox/EnemyColor
@onready var master_s := $MarginContainer/VBoxContainer/TabContainer/Sound/VBoxContainer/MasterSlider
@onready var sfx_s := $MarginContainer/VBoxContainer/TabContainer/Sound/VBoxContainer/SFXSlider
@onready var bgm_s := $MarginContainer/VBoxContainer/TabContainer/Sound/VBoxContainer/BGMSlider
@onready var camera_margin_s := $MarginContainer/VBoxContainer/TabContainer/Game/HBoxContainer/LeftBox/CameraMarginSlider

func _ready() -> void:
	set_settings()

func set_settings():
	temp_settings = RTS.game_settings
	
	camera_options.selected = temp_settings.movement_type
	camera_speed.value = temp_settings.camera_move_speed
	selection_color_picker.color = temp_settings.select_color
	enemy_color_picker.color = temp_settings.enemy_color
	$MarginContainer/VBoxContainer/TabContainer/Game/HBoxContainer/LeftBox/MoveSpeedLabel.text = str(temp_settings.camera_move_speed) + " px/s"
	master_s.value = temp_settings.default_master
	sfx_s.value = temp_settings.default_sfx
	bgm_s.value = temp_settings.default_bgm
	camera_margin_s.value = temp_settings.camera_move_margin
	
	settings_changed = false

func _on_back_button_pressed() -> void:
	if settings_changed:
		save_popup.popup()
		return
	get_tree().change_scene_to_file("res://menu/main_menus/title_screen.tscn")


func _on_save_button_pressed() -> void:
	RTS.game_settings = temp_settings
	AudioServer.set_bus_volume_db(0, temp_settings.default_master)
	AudioServer.set_bus_volume_db(1, temp_settings.default_bgm)
	AudioServer.set_bus_volume_db(2, temp_settings.default_sfx)
	ResourceSaver.save(temp_settings, RTS.SAVE_PATH + "settings.tres")
	RTS.settings_changed.emit()
	settings_changed = false


func _on_camera_control_options_item_selected(index: int) -> void:
	temp_settings.movement_type = index
	settings_changed = true


func _on_camera_speed_slider_value_changed(value: float) -> void:
	temp_settings.camera_move_speed = value
	settings_changed = true


func _on_selection_color_color_changed(color: Color) -> void:
	temp_settings.select_color = color
	settings_changed = true


func _on_enemy_color_color_changed(color: Color) -> void:
	temp_settings.enemy_color = color
	settings_changed = true


func _on_master_slider_value_changed(value: float) -> void:
	temp_settings.default_master = value
	AudioServer.set_bus_volume_db(0, value)
	settings_changed = true


func _on_sfx_slider_value_changed(value: float) -> void:
	temp_settings.default_sfx = value
	AudioServer.set_bus_volume_db(2, value)
	settings_changed = true


func _on_bgm_slider_value_changed(value: float) -> void:
	temp_settings.default_bgm = value
	AudioServer.set_bus_volume_db(1, value)
	settings_changed = true


func _on_reset_pressed() -> void:
	temp_settings = ResourceLoader.load("res://menu/settings/default_settings.tres")
	ResourceSaver.save(temp_settings, RTS.SAVE_PATH + "settings.tres")
	RTS.game_settings = temp_settings
	RTS.settings_changed.emit()
	set_settings()
	settings_changed = false


func _on_camera_margin_slider_value_changed(value: float) -> void:
	pass # Replace with function body.
