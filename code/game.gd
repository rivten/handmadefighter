
extends Node2D

var Root
var HitboxScene = preload("res://StaticHitbox.tscn")
var HitboxWr
var HitboxInitialPos = Vector2(0, -120)
var Hitbox

func instanciate_hitbox():
	Hitbox = HitboxScene.instance()
	HitboxWr = weakref(Hitbox) # this is used to check existence of Hitbox

	Root.add_child(Hitbox)
	Hitbox.set_owner(Root)
	Hitbox.set_pos(HitboxInitialPos)

func _ready():
	set_fixed_process(false)

	Root = get_node("/root").get_child(0)
	instanciate_hitbox()

	var TimerNode = find_node("Timer")
	TimerNode.connect("timeout", self, "OnTimerTimeout")

func OnTimerTimeout():
	# TODO(hugo) : Is the root this very node ?
	var HitboxExists = HitboxWr.get_ref()
	if (!HitboxExists):
		instanciate_hitbox()
