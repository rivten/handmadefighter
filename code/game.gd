
extends Node2D

var Root
var HitboxScene = preload("res://StaticHitbox.tscn")
var HitboxWeakRef
var HitboxInitialPos = Vector2(0, -120)
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

func respawn_hitbox():
	var HitboxExists = HitboxWeakRef.get_ref()
	if (!HitboxExists):
		instanciate_hitbox()
