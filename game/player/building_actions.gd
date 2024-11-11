extends PanelContainer

@onready var name_label := $MarginContainer/VBoxContainer/NameLabel
@onready var action_tab_container := $MarginContainer/VBoxContainer/HBoxContainer/BuildingActions

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RTS.select_list_changed.connect(select_list_changed)
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if visible and RTS.selected_building:
		match RTS.selected_building.unit_id:
			0:	# Testing building
				pass
			1:	# Core
				pass
			2:	# Military Base
				pass
			3:
				pass
			4:
				pass
			_:
				pass

func select_list_changed():
	if RTS.selected_building:
		show()
		name_label.text = RTS.selected_building.unit_name
		action_tab_container.current_tab = RTS.selected_building.unit_id
	else:
		hide()
