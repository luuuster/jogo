class_name EnemyAI
extends RefCounted

static func choose_target(actor: UnitModel, units: Array[UnitModel]) -> UnitModel:
	var enemies := units.filter(func(unit): return unit.team != actor.team and unit.is_alive())
	if enemies.is_empty(): return null
	enemies.sort_custom(func(a, b):
		var score_a := CombatRules.distance(actor.position, a.position) * 10 + a.hp
		var score_b := CombatRules.distance(actor.position, b.position) * 10 + b.hp
		return score_a < score_b)
	return enemies[0]

static func choose_destination(actor: UnitModel, target: UnitModel, grid: GridModel) -> Vector2i:
	var options := grid.reachable(actor.position, actor.movement, actor).keys()
	options.sort_custom(func(a, b): return CombatRules.distance(a, target.position) < CombatRules.distance(b, target.position))
	return options[0] if not options.is_empty() else actor.position
