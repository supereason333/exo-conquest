extends Resource
class_name MaterialCost

@export var selnite:int
@export var luminite:int
@export var plainium:int
@export var xenite:int

func _init(_selnite:int = 0, _luminite:int = 0, _plainium:int = 0, _xenite:int = 0):
	selnite = _selnite
	luminite = _luminite
	plainium = _plainium
	xenite = _xenite

func add(other:MaterialCost) -> MaterialCost:
	var result := self.duplicate()
	
	result.selnite += other.selnite
	result.luminite += other.luminite
	result.plainium += other.plainium
	result.xenite += other.xenite
	
	return result

func subtract(other:MaterialCost) -> MaterialCost:
	if other is MaterialCost:
		var result := self.duplicate()
		
		result.selnite -= other.selnite
		result.luminite -= other.luminite
		result.plainium -= other.plainium
		result.xenite -= other.xenite
		
		return result
	return null

func can_afford(cost:MaterialCost) -> bool:
	var remaining := subtract(cost)
	if remaining:
		if remaining.selnite < 0: return false
		if remaining.luminite < 0: return false
		if remaining.plainium < 0: return false
		if remaining.xenite < 0: return false
	else:
		return false
	return true

func _to_string() -> String:
	return "[" + str(selnite) + ", " + str(luminite) + ", " + str(plainium) + ", " + str(xenite) + "]"
