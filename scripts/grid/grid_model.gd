class_name GridModel
extends RefCounted

const DIRECTIONS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
var size := Vector2i(10, 10)
var cells: Dictionary = {}

func _init(board_size := Vector2i(10, 10)):
	size = board_size
	for y in size.y:
		for x in size.x:
			cells[Vector2i(x, y)] = GridCell.new(Vector2i(x, y))

func is_inside(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < size.x and coord.y < size.y

func cell(coord: Vector2i) -> GridCell:
	return cells.get(coord)

func set_terrain(coord: Vector2i, terrain: String, cost: int, blocked := false) -> void:
	var target := cell(coord)
	if target:
		target.terrain = terrain
		target.movement_cost = cost
		target.blocked = blocked

func reachable(start: Vector2i, budget: int, mover = null) -> Dictionary:
	var costs := {start: 0}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var current := frontier.pop_front()
		for direction in DIRECTIONS:
			var next := current + direction
			if not is_inside(next): continue
			var tile := cell(next)
			if tile.blocked or (tile.occupant != null and tile.occupant != mover): continue
			var new_cost: int = costs[current] + tile.movement_cost
			if new_cost <= budget and (not costs.has(next) or new_cost < costs[next]):
				costs[next] = new_cost
				frontier.append(next)
	return costs

func shortest_path(start: Vector2i, goal: Vector2i, budget: int, mover = null) -> Array[Vector2i]:
	var costs := {start: 0}
	var previous := {}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		frontier.sort_custom(func(a, b): return costs[a] < costs[b])
		var current := frontier.pop_front()
		if current == goal: break
		for direction in DIRECTIONS:
			var next := current + direction
			if not is_inside(next): continue
			var tile := cell(next)
			if tile.blocked or (tile.occupant != null and tile.occupant != mover): continue
			var new_cost: int = costs[current] + tile.movement_cost
			if new_cost <= budget and (not costs.has(next) or new_cost < costs[next]):
				costs[next] = new_cost
				previous[next] = current
				if next not in frontier: frontier.append(next)
	if not costs.has(goal): return []
	var path: Array[Vector2i] = [goal]
	while path[0] != start: path.push_front(previous[path[0]])
	return path

static func logical_to_visual(coord: Vector2i, origin: Vector2, tile_size: float) -> Vector2:
	return origin + Vector2(coord) * tile_size

static func visual_to_logical(point: Vector2, origin: Vector2, tile_size: float) -> Vector2i:
	return Vector2i(floor((point.x - origin.x) / tile_size), floor((point.y - origin.y) / tile_size))
