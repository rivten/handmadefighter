
extends Node2D

var Root
var HitboxScene = preload("res://StaticHitbox.tscn")

var LeftHitboxInitialPos = Vector2(300, 170)
var LeftHitboxWeakRef
var LeftHitbox

var RightHitboxInitialPos = Vector2(600, 170)
var RightHitboxWeakRef
var RightHitbox

func instanciate_left_hitbox():
	LeftHitbox = HitboxScene.instance()
	LeftHitboxWeakRef = weakref(LeftHitbox) # this is used to check existence of Hitbox

	Root.add_child(LeftHitbox)
	LeftHitbox.set_owner(Root)
	LeftHitbox.set_pos(LeftHitboxInitialPos)

func instanciate_right_hitbox():
	RightHitbox = HitboxScene.instance()
	RightHitboxWeakRef = weakref(RightHitbox) # this is used to check existence of Hitbox

	Root.add_child(RightHitbox)
	RightHitbox.set_owner(Root)
	RightHitbox.set_pos(RightHitboxInitialPos)

func _ready():
	set_fixed_process(false)

	Root = get_node("/root").get_child(0)
	instanciate_left_hitbox()
	instanciate_right_hitbox()

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
	var LeftHitboxExists = LeftHitboxWeakRef.get_ref()
	if (!LeftHitboxExists):
		instanciate_left_hitbox()

	var RightHitboxExists = RightHitboxWeakRef.get_ref()
	if (!RightHitboxExists):
		instanciate_right_hitbox()
