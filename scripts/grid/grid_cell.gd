class_name GridCell
extends RefCounted

var coord: Vector2i
var height: int = 0
var terrain: String = "plain"
var occupant = null
var movement_cost: int = 1
var blocked: bool = false

func _init(at: Vector2i, kind := "plain", cost := 1, is_blocked := false):
	coord = at
	terrain = kind
	movement_cost = cost
	blocked = is_blocked
