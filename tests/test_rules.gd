extends SceneTree

var failures := 0

func check(condition: bool, label: String) -> void:
	if condition: print("PASS: ", label)
	else: push_error("FAIL: " + label); failures += 1

func _init() -> void:
	var grid := GridModel.new(Vector2i(5,5))
	grid.set_terrain(Vector2i(1,0), "wall", 99, true)
	var reached := grid.reachable(Vector2i(0,0), 2)
	check(not reached.has(Vector2i(1,0)), "obstáculos não podem ser atravessados")
	check(reached.has(Vector2i(0,2)) and not reached.has(Vector2i(0,3)), "pontos limitam movimento")
	var data := {"id":"test","name":"Teste","archetype":"guerreiro","hp":10,"mp":5,"attack":7,"defense":2,"speed":5,"movement":3,"range":1,"skill":{"power":3,"range":2,"mp_cost":2}}
	var ally := UnitModel.new(data, "ally", Vector2i(0,0))
	var enemy := UnitModel.new(data, "enemy", Vector2i(0,2))
	check(not CombatRules.can_target(ally, enemy), "ataque respeita alcance")
	check(CombatRules.can_target(ally, enemy, true), "habilidade usa alcance configurado")
	check(CombatRules.damage(ally, enemy) == 5, "dano é determinístico")
	var dead := UnitModel.new(data, "enemy", Vector2i(1,1)); dead.hp = 0
	var roster: Array[UnitModel] = [ally, dead, enemy]
	var turns := TurnManager.new(roster)
	turns.next_turn()
	check(dead not in turns.queue and turns.active != dead, "derrotados não recebem turnos")
	enemy.hp = 0
	check(turns.battle_result() == "victory", "vitória é detectada")
	ally.hp = 0; enemy.hp = 10
	check(turns.battle_result() == "defeat", "derrota é detectada")
	quit(failures)
