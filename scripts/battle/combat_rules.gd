class_name CombatRules
extends RefCounted

static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

static func can_target(attacker: UnitModel, target: UnitModel, use_skill := false) -> bool:
	if not attacker.is_alive() or not target.is_alive() or attacker.team == target.team: return false
	var reach: int = attacker.skill.get("range", attacker.attack_range) if use_skill else attacker.attack_range
	return distance(attacker.position, target.position) <= reach

static func damage(attacker: UnitModel, target: UnitModel, use_skill := false) -> int:
	var power: int = attacker.skill.get("power", 0) if use_skill else 0
	return maxi(1, attacker.attack + power - target.defense)

static func resolve(attacker: UnitModel, target: UnitModel, use_skill := false) -> int:
	if not can_target(attacker, target, use_skill): return 0
	if use_skill:
		var cost: int = attacker.skill.get("mp_cost", 0)
		if attacker.mp < cost: return 0
		attacker.mp -= cost
	var dealt := damage(attacker, target, use_skill)
	target.hp = maxi(0, target.hp - dealt)
	return dealt
