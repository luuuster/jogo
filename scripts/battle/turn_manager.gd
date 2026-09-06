class_name TurnManager
extends RefCounted

enum State { TURN_START, UNIT_SELECTION, MOVEMENT, ACTION_SELECTION, TARGET_SELECTION, RESOLUTION, TURN_END, FINISHED }
var state := State.TURN_START
var units: Array[UnitModel] = []
var queue: Array[UnitModel] = []
var active: UnitModel

func _init(roster: Array[UnitModel]):
	units = roster

func next_turn() -> UnitModel:
	queue = queue.filter(func(unit): return unit.is_alive())
	if queue.is_empty():
		queue = units.filter(func(unit): return unit.is_alive())
		queue.sort_custom(func(a, b): return a.speed > b.speed)
	active = queue.pop_front() if not queue.is_empty() else null
	if active:
		active.acted = false
		state = State.MOVEMENT
	return active

func battle_result() -> String:
	var allies := units.any(func(unit): return unit.team == "ally" and unit.is_alive())
	var enemies := units.any(func(unit): return unit.team == "enemy" and unit.is_alive())
	if not enemies: return "victory"
	if not allies: return "defeat"
	return "ongoing"
