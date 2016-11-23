
extends Node2D

var Root
var HitboxScene = preload("res://StaticHitbox.tscn")
var HitboxWeakRef
var HitboxInitialPos = Vector2(300, 170)
var Hitbox

func instanciate_hitbox():
	Hitbox = HitboxScene.instance()
	HitboxWeakRef = weakref(Hitbox) # this is used to check existence of Hitbox

	Root.add_child(Hitbox)
	Hitbox.set_owner(Root)
	Hitbox.set_pos(HitboxInitialPos)

func _ready():
	set_fixed_process(false)

	Root = get_node("/root").get_child(0)
	instanciate_hitbox()

	var TimerNode = find_node("Timer")
	TimerNode.connect("timeout", self, "respawn_hitbox")

	# NOTE(hugo) : Settings of the first fighter
	var Fighter = find_node("Fighter")
	Fighter.set_pos(Vector2(300, 400))

	# NOTE(hugo) : Settings of the second fighter
	var Fighter2 = find_node("Fighter2")
	Fighter2.set_pos(Vector2(600, 400))
	Fighter2.set_input_map("up1", "down1", "left1")
	Fighter2.BulletDir = Vector2(-1.0, 0.0)


func respawn_hitbox():
	var HitboxExists = HitboxWeakRef.get_ref()
	if (!HitboxExists):
		instanciate_hitbox()
