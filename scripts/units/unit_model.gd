class_name UnitModel
extends RefCounted

var id: String
var display_name: String
var team: String
var archetype: String
var max_hp: int
var hp: int
var max_mp: int
var mp: int
var attack: int
var defense: int
var speed: int
var movement: int
var attack_range: int
var skill: Dictionary
var position: Vector2i
var acted := false

func _init(data: Dictionary, unit_team: String, at: Vector2i):
	id = data.id
	display_name = data.name
	team = unit_team
	archetype = data.archetype
	max_hp = data.hp; hp = max_hp
	max_mp = data.mp; mp = max_mp
	attack = data.attack; defense = data.defense
	speed = data.speed; movement = data.movement; attack_range = data.range
	skill = data.skill
	position = at

func is_alive() -> bool:
	return hp > 0
