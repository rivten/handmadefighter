
extends Node2D

func _ready():
	set_fixed_process(false)

	var Root = get_node("/root").get_child(0)
	var Hitbox = preload("res://StaticHitbox.tscn").instance()

	Root.add_child(Hitbox)
	Hitbox.set_owner(Root)

	# NOTE(hugo) : Hard-coding the initial pos of the hitbox
	Hitbox.set_pos(Vector2(0, -120))
