
extends Node2D

var GameNode
var HitboxScene = preload("res://StaticHitbox.tscn")

var LeftHitboxInitialPos
var LeftHitboxWeakRef
var LeftHitbox

var RightHitboxInitialPos
var RightHitboxWeakRef
var RightHitbox

var DamageCounter

export(int, 100, 500) var FighterMargin = 200
const FIGHTER_HORIZONTAL_INIT_POS = 400
const HITBOX_HORIZONTAL_INIT_POS = 170

export(bool) var EnableDebugTools = true

#################################
# NOTE(hugo) : This is debug code
func instanciate_left_hitbox():
	LeftHitbox = HitboxScene.instance()
	LeftHitboxWeakRef = weakref(LeftHitbox) # this is used to check existence of Hitbox

	GameNode.add_child(LeftHitbox)
	LeftHitbox.set_owner(GameNode)
	LeftHitbox.set_pos(LeftHitboxInitialPos)

func instanciate_right_hitbox():
	RightHitbox = HitboxScene.instance()
	RightHitboxWeakRef = weakref(RightHitbox) # this is used to check existence of Hitbox

	GameNode.add_child(RightHitbox)
	RightHitbox.set_owner(GameNode)
	RightHitbox.set_pos(RightHitboxInitialPos)
#################################

func _draw():
	# NOTE(hugo) : This is DEBUG code to see the homeline of each fighter
	# {
	var WindowSize = get_viewport().get_rect().size
	draw_line(Vector2(FighterMargin, 0), Vector2(FighterMargin, WindowSize.y), Color(255, 0, 0), 2)
	draw_line(Vector2(WindowSize.x - FighterMargin, 0), Vector2(WindowSize.x - FighterMargin, WindowSize.y), Color(255, 0, 0), 2)
	# }

func _ready():
	set_fixed_process(false)
	set_process(EnableDebugTools)
	var WindowSize = get_viewport().get_rect().size
	LeftHitboxInitialPos = Vector2(FighterMargin, HITBOX_HORIZONTAL_INIT_POS)
	RightHitboxInitialPos = Vector2(WindowSize.x - FighterMargin, HITBOX_HORIZONTAL_INIT_POS)
	GameNode = get_node("/root").get_node("Game")
	instanciate_left_hitbox()
	instanciate_right_hitbox()

	var TimerNode = find_node("Timer")
	TimerNode.connect("timeout", self, "respawn_hitbox")

	# NOTE(hugo) : Settings of the first fighter
	var Fighter = find_node("Fighter")
	Fighter.InitPos = Vector2(FighterMargin, FIGHTER_HORIZONTAL_INIT_POS)
	Fighter.set_pos(Fighter.InitPos)

	# NOTE(hugo) : Settings of the second fighter
	var Fighter2 = find_node("Fighter2")
	Fighter2.InitPos = Vector2(WindowSize.x - FighterMargin, FIGHTER_HORIZONTAL_INIT_POS)
	Fighter2.set_pos(Fighter2.InitPos)
	Fighter2.set_input_map("up1", "down1", "left1", "use1", "control1")
	Fighter2.BulletDir = Vector2(-1.0, 0.0)

	DamageCounter = find_node("DamageCounter")

# NOTE(hugo) : For now, this function is only used if EnableDebugTools = true.
# If you want to use this function for non-debug purposes, you might want to change
# set_process() in _ready.
func _process(dt):
	if(Input.is_key_pressed(KEY_SPACE)):
		DamageCounter.set_text(str(0))


func respawn_hitbox():
	var LeftHitboxExists = LeftHitboxWeakRef.get_ref()
	if (!LeftHitboxExists):
		instanciate_left_hitbox()

	var RightHitboxExists = RightHitboxWeakRef.get_ref()
	if (!RightHitboxExists):
		instanciate_right_hitbox()


func increase_damage_counter(FighterName, Damage):
	if(FighterName == 'Fighter'):
		var NewDamage = (DamageCounter.get_text().to_int()) + Damage
		DamageCounter.set_text(str(NewDamage))
