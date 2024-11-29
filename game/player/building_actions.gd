extends PanelContainer

@onready var name_label := $MarginContainer/VBoxContainer/HBoxContainer2/NameLabel
@onready var health_bar := $MarginContainer/VBoxContainer/HBoxContainer2/ProgressBar
@onready var health_label := $MarginContainer/VBoxContainer/HBoxContainer2/Label
@onready var building_icon := $MarginContainer/VBoxContainer/HBoxContainer/BuildingIcon
@onready var unit_display := $MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/CenterContainer
@onready var container_tabs := $MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/TabContainer

var last_building:BaseBuilding

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RTS.select_list_changed.connect(select_list_changed)

func select_list_changed():
	if RTS.selected_building:
		if !is_instance_valid(last_building):
			last_building = null
		show()
		unit_display.hide()
		building_icon.show()
		health_label.show()
		health_bar.show()
		container_tabs.show()
		if last_building != RTS.selected_building:
			if last_building:
				last_building.taken_damage.disconnect(update_display_data)
			last_building = RTS.selected_building
			RTS.selected_building.taken_damage.connect(update_display_data)
		health_bar.max_value = RTS.selected_building.base_health
		update_display_data()
	elif RTS.selected_list:
		show()
		unit_display.show()
		building_icon.hide()
		health_label.hide()
		health_bar.hide()
		container_tabs.hide()
		name_label.text = "Selected units"
		update_display_data()
	else:
		hide()

func update_display_data():
	if RTS.selected_building:
		if !RTS.selected_building.is_owned_by_user():
			name_label.modulate = Color.RED
			building_icon.modulate = Color.RED
			container_tabs.current_tab = 0
		else:
			name_label.modulate = Color.WHITE
			building_icon.modulate = Color.WHITE
			if RTS.selected_building.production_component:
				container_tabs.current_tab = 1
			else:
				container_tabs.current_tab = 0
		
		name_label.text = RTS.selected_building.unit_name
		health_bar.value = RTS.selected_building.health
		building_icon.texture = RTS.selected_building.display_icon
	elif RTS.selected_list:
		if !RTS.selected_controllable:
			name_label.modulate = Color.RED
			building_icon.modulate = Color.RED
			container_tabs.current_tab = 0
		else:
			name_label.modulate = Color.WHITE
			building_icon.modulate = Color.WHITE
			container_tabs.current_tab = 0
