extends Node2D

const TILE := 56.0
const ORIGIN := Vector2(36, 92)
const ALLY_COLOR := Color("55d6be")
const ENEMY_COLOR := Color("f07178")

var grid: GridModel
var units: Array[UnitModel] = []
var turns: TurnManager
var reachable := {}
var mode := "menu"
var selected_action := ""
var message := ""
var hover := Vector2i(-1, -1)
var ui_rects := {}
var resolving := false

func _ready() -> void:
	set_process_input(true)
	queue_redraw()

func start_battle() -> void:
	grid = GridModel.new()
	for rock in [Vector2i(4,2), Vector2i(4,3), Vector2i(4,4), Vector2i(6,6), Vector2i(7,6)]:
		grid.set_terrain(rock, "ruins", 99, true)
	for marsh in [Vector2i(2,4), Vector2i(2,5), Vector2i(3,5), Vector2i(7,3)]:
		grid.set_terrain(marsh, "moss", 2)
	var file := FileAccess.open("res://resources/units.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	units = [
		UnitModel.new(data.warden, "ally", Vector2i(1,4)),
		UnitModel.new(data.ranger, "ally", Vector2i(1,6)),
		UnitModel.new(data.raider, "enemy", Vector2i(8,2)),
		UnitModel.new(data.raider.duplicate(true), "enemy", Vector2i(8,5)),
		UnitModel.new(data.seer, "enemy", Vector2i(8,8))]
	units[2].display_name = "Vark"; units[3].display_name = "Rusk"
	for unit in units: grid.cell(unit.position).occupant = unit
	turns = TurnManager.new(units)
	mode = "battle"
	message = "Proteja o Farol. Escolha uma casa para mover."
	next_turn()

func next_turn() -> void:
	var result := turns.battle_result()
	if result != "ongoing":
		mode = result
		message = "O Farol resiste!" if result == "victory" else "A luz do Farol se apagou."
		queue_redraw(); return
	var actor := turns.next_turn()
	if actor.team == "enemy":
		message = "%s está agindo..." % actor.display_name
		reachable.clear(); queue_redraw()
		get_tree().create_timer(0.45).timeout.connect(run_enemy_turn)
	else:
		selected_action = ""
		reachable = grid.reachable(actor.position, actor.movement, actor)
		message = "Turno de %s • escolha o destino" % actor.display_name
	queue_redraw()

func move_unit(unit: UnitModel, destination: Vector2i) -> void:
	grid.cell(unit.position).occupant = null
	unit.position = destination
	grid.cell(destination).occupant = unit

func run_enemy_turn() -> void:
	if mode != "battle": return
	resolving = true
	var actor := turns.active
	var target := EnemyAI.choose_target(actor, units)
	if target:
		var destination := EnemyAI.choose_destination(actor, target, grid)
		move_unit(actor, destination)
		if CombatRules.can_target(actor, target):
			var dealt := CombatRules.resolve(actor, target)
			message = "%s causou %d de dano em %s." % [actor.display_name, dealt, target.display_name]
			remove_defeated()
		else: message = "%s avançou pelo campo." % actor.display_name
	queue_redraw()
	await get_tree().create_timer(0.55).timeout
	resolving = false
	next_turn()

func remove_defeated() -> void:
	for unit in units:
		if not unit.is_alive() and grid.cell(unit.position).occupant == unit:
			grid.cell(unit.position).occupant = null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover = GridModel.visual_to_logical(event.position, ORIGIN, TILE)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_action(); return
		if event.button_index != MOUSE_BUTTON_LEFT: return
		for key in ui_rects:
			if ui_rects[key].has_point(event.position):
				handle_button(key); return
		if mode == "battle" and turns.active and turns.active.team == "ally" and not resolving:
			handle_grid_click(GridModel.visual_to_logical(event.position, ORIGIN, TILE))
	if event.is_action_pressed("cancel_action"): cancel_action()

func handle_button(key: String) -> void:
	match key:
		"start", "restart": start_battle()
		"menu": mode = "menu"; message = ""; queue_redraw()
		"attack": begin_targeting("attack")
		"skill": begin_targeting("skill")
		"wait": finish_ally_turn()
		"cancel": cancel_action()

func handle_grid_click(coord: Vector2i) -> void:
	if not grid.is_inside(coord): return
	var actor := turns.active
	if selected_action.is_empty():
		if reachable.has(coord):
			move_unit(actor, coord)
			reachable.clear()
			turns.state = TurnManager.State.ACTION_SELECTION
			message = "Escolha uma ação para %s." % actor.display_name
	else:
		var target = grid.cell(coord).occupant
		var use_skill := selected_action == "skill"
		if target and CombatRules.can_target(actor, target, use_skill):
			var dealt := CombatRules.resolve(actor, target, use_skill)
			if dealt == 0:
				message = "MP insuficiente para usar a habilidade."
			else:
				message = "%s causa %d de dano em %s!" % [actor.display_name, dealt, target.display_name]
				remove_defeated(); finish_ally_turn()
		else: message = "Alvo inválido ou fora do alcance."
	queue_redraw()

func begin_targeting(action: String) -> void:
	if turns.state != TurnManager.State.ACTION_SELECTION: return
	selected_action = action
	turns.state = TurnManager.State.TARGET_SELECTION
	message = "Selecione um alvo em vermelho."
	queue_redraw()

func cancel_action() -> void:
	if mode != "battle" or not turns.active or turns.active.team != "ally": return
	if not selected_action.is_empty():
		selected_action = ""; turns.state = TurnManager.State.ACTION_SELECTION
		message = "Ação cancelada. Escolha novamente."
	queue_redraw()

func finish_ally_turn() -> void:
	selected_action = ""
	turns.active.acted = true
	turns.state = TurnManager.State.TURN_END
	queue_redraw()
	get_tree().create_timer(0.45).timeout.connect(next_turn)

func _draw() -> void:
	ui_rects.clear()
	if mode == "menu": draw_menu(); return
	draw_board()
	draw_sidebar()
	if mode in ["victory", "defeat"]: draw_result()

func draw_menu() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(90,170), "CRÔNICAS DE LÚMEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color("f5d76e"))
	draw_string(ThemeDB.fallback_font, Vector2(94,215), "Uma batalha tática original", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("9fb3c8"))
	draw_string(ThemeDB.fallback_font, Vector2(94,285), "O Farol ancestral é a última defesa do vale.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_button("start", Rect2(94,340,240,58), "INICIAR BATALHA", Color("355c7d"))

func draw_board() -> void:
	for y in grid.size.y:
		for x in grid.size.x:
			var coord := Vector2i(x,y); var tile := grid.cell(coord)
			var rect := Rect2(GridModel.logical_to_visual(coord, ORIGIN, TILE), Vector2(TILE-2,TILE-2))
			var color := Color("20364b") if (x+y)%2 == 0 else Color("263f55")
			if tile.terrain == "moss": color = Color("41685a")
			if tile.blocked: color = Color("596273")
			if reachable.has(coord): color = Color("276a85")
			if selected_action and tile.occupant and CombatRules.can_target(turns.active, tile.occupant, selected_action == "skill"): color = Color("8c3f52")
			if coord == hover: color = color.lightened(0.16)
			draw_rect(rect, color)
			if tile.blocked:
				draw_circle(rect.get_center(), 15, Color("8994a5")); draw_line(rect.position+Vector2(15,38),rect.position+Vector2(40,15),Color("4d5564"),5)
	for unit in units:
		if not unit.is_alive(): continue
		var center := GridModel.logical_to_visual(unit.position, ORIGIN, TILE) + Vector2(TILE/2-1,TILE/2-1)
		var color := ALLY_COLOR if unit.team == "ally" else ENEMY_COLOR
		if unit == turns.active: draw_arc(center,23,0,TAU,32,Color("f5d76e"),4)
		draw_circle(center,18,color); draw_circle(center,12,color.darkened(0.28))
		draw_string(ThemeDB.fallback_font, center+Vector2(-13,5), unit.display_name.left(2).to_upper(), HORIZONTAL_ALIGNMENT_CENTER,26,13,Color.WHITE)
		var ratio := float(unit.hp)/unit.max_hp
		draw_rect(Rect2(center+Vector2(-20,21),Vector2(40,5)),Color("491f2f")); draw_rect(Rect2(center+Vector2(-20,21),Vector2(40*ratio,5)),Color("6ee7a0"))

func draw_sidebar() -> void:
	var panel := Rect2(620,36,445,648)
	draw_rect(panel,Color("101c2d")); draw_rect(panel,Color("38506b"),false,2)
	draw_string(ThemeDB.fallback_font,Vector2(648,78),"FAROL DE LÚMEN",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("f5d76e"))
	if turns and turns.active:
		var a := turns.active
		draw_string(ThemeDB.fallback_font,Vector2(648,125),"ATIVO  %s"%a.display_name,HORIZONTAL_ALIGNMENT_LEFT,-1,22,ALLY_COLOR if a.team=="ally" else ENEMY_COLOR)
		draw_string(ThemeDB.fallback_font,Vector2(648,155),"HP %d/%d     MP %d/%d"%[a.hp,a.max_hp,a.mp,a.max_mp],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
		draw_string(ThemeDB.fallback_font,Vector2(648,184),"%s  •  MOV %d  •  ALC %d"%[a.archetype.to_upper(),a.movement,a.attack_range],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("9fb3c8"))
	if turns and turns.active and turns.active.team == "ally" and turns.state == TurnManager.State.ACTION_SELECTION:
		draw_button("attack",Rect2(648,214,120,45),"ATAQUE",Color("355c7d"))
		draw_button("skill",Rect2(778,214,150,45),turns.active.skill.name.to_upper(),Color("644b76"),12)
		draw_button("wait",Rect2(938,214,95,45),"ESPERAR",Color("555f70"),12)
	if selected_action: draw_button("cancel",Rect2(648,214,130,45),"CANCELAR",Color("704454"))
	draw_string(ThemeDB.fallback_font,Vector2(648,302),"ORDEM DE TURNOS",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("9fb3c8"))
	var ordered := units.filter(func(u): return u.is_alive()); ordered.sort_custom(func(a,b): return a.speed>b.speed)
	for i in ordered.size():
		var u: UnitModel = ordered[i]
		draw_string(ThemeDB.fallback_font,Vector2(654,334+i*29),"%d. %s     HP %d"%[i+1,u.display_name,u.hp],HORIZONTAL_ALIGNMENT_LEFT,-1,16,ALLY_COLOR if u.team=="ally" else ENEMY_COLOR)
	draw_rect(Rect2(642,510,400,92),Color("17283c"))
	draw_multiline_string(ThemeDB.fallback_font,Vector2(656,535),message,HORIZONTAL_ALIGNMENT_LEFT,370,16,16,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(648,637),"Azul: movimento  •  Vermelho: alvo",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("9fb3c8"))

func draw_result() -> void:
	draw_rect(Rect2(190,220,720,260),Color(0.03,0.05,0.1,0.95)); draw_rect(Rect2(190,220,720,260),Color("f5d76e"),false,3)
	var title := "VITÓRIA" if mode == "victory" else "DERROTA"
	draw_string(ThemeDB.fallback_font,Vector2(190,295),title,HORIZONTAL_ALIGNMENT_CENTER,720,40,Color("f5d76e") if mode=="victory" else ENEMY_COLOR)
	draw_string(ThemeDB.fallback_font,Vector2(190,340),message,HORIZONTAL_ALIGNMENT_CENTER,720,20,Color.WHITE)
	draw_button("restart",Rect2(300,385,220,52),"JOGAR NOVAMENTE",Color("355c7d"))
	draw_button("menu",Rect2(540,385,160,52),"MENU",Color("555f70"))

func draw_button(key: String, rect: Rect2, label: String, color: Color, font_size := 14) -> void:
	ui_rects[key] = rect
	draw_rect(rect,color); draw_rect(rect,color.lightened(0.3),false,2)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(0,rect.size.y/2+font_size/3),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,font_size,Color.WHITE)
