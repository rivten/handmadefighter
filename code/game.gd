
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

func deathline_equation(Y, WindowSize):
	# NOTE(hugo) : This is where there is a problem with Godot. I would like to get rid of the WindowSize in this equation.
	# The deathline should _not_ be dependant on the screen current resolution. Me is sad :(
	return(0.75 * WindowSize.x - 0.002 * (Y - 0.5 * WindowSize.y) * (Y - 0.5 * WindowSize.y))

func _draw():
	var WindowSize = get_viewport().get_rect().size
	var StepCount = 100
	var Epsilon = WindowSize.y / StepCount
	for StepIndex in range(StepCount):
		var YBegin = StepIndex * Epsilon
		var YEnd = (StepIndex + 1) * Epsilon
		var XBegin = deathline_equation(YBegin, WindowSize)
		var XEnd = deathline_equation(YEnd, WindowSize)
		draw_line(Vector2(XBegin, YBegin), Vector2(XEnd, YEnd), Color(236, 88, 0), 1)

func _ready():
	set_fixed_process(false)
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
	Fighter.set_pos(Vector2(FighterMargin, FIGHTER_HORIZONTAL_INIT_POS))

	# NOTE(hugo) : Settings of the second fighter
	var Fighter2 = find_node("Fighter2")
	Fighter2.set_pos(Vector2(WindowSize.x - FighterMargin, FIGHTER_HORIZONTAL_INIT_POS))
	Fighter2.set_input_map("up1", "down1", "left1")
	Fighter2.BulletDir = Vector2(-1.0, 0.0)

	DamageCounter = find_node("DamageCounter")

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
