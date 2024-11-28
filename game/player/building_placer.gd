extends HBoxContainer

var Numbered_button := preload("res://menu/menu_resources/numbered_button.tscn")

signal add_new_building(building_id:int)

const BLACKLIST:Array[int] = [0, 1]

@onready var material_display := $PanelContainer/MarginContainer/MaterialDisplay
@onready var buildings_grid := $PanelContainer2/Buildings

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in BuildingLoader.MAX_BUILDINGS:
		var build := BuildingLoader.load_building_from_id(i)
		if build and !BLACKLIST.has(i):
			var numbered_button := Numbered_button.instantiate()
			numbered_button.number = i
			numbered_button.pressed_n.connect(on_numbered_button_clicked)
			numbered_button.mouse_entered_n.connect(on_numbered_button_mouse_entered)
			numbered_button.mouse_exited_n.connect(on_numbered_button_mouse_exited)
			numbered_button.texture_normal = build.display_icon
			numbered_button.texture_pressed = build.display_icon
			numbered_button.texture_hover = build.display_icon
			numbered_button.texture_disabled = build.display_icon
			numbered_button.texture_focused = build.display_icon
			numbered_button.tooltip_text = build.unit_name
			buildings_grid.add_child(numbered_button)

func on_numbered_button_clicked(number:int):
	var build := BuildingLoader.load_building_from_id(number)
	if RTS.materials.can_afford(build.unit_cost):
		RTS.materials = RTS.materials.subtract(build.unit_cost)
		emit_signal("add_new_building", number)

func on_numbered_button_mouse_entered(number:int):
	material_display.set_costs(BuildingLoader.load_building_from_id(number).unit_cost)

func on_numbered_button_mouse_exited(_number:int):
	material_display.set_costs(MaterialCost.new(0, 0, 0, 0))
