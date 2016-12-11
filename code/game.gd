
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

var LeftLifeAreaNode

export(int, 100, 500) var FighterMargin = 200
const FIGHTER_HORIZONTAL_INIT_POS = 400
const HITBOX_HORIZONTAL_INIT_POS = 170

signal reset_damage

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

func deathline_equation(Y, WindowSize):
	# NOTE(hugo) : This is where there is a problem with Godot. I would like to get rid of the WindowSize in this equation.
	# The deathline should _not_ be dependant on the screen current resolution. Me is sad :(
	return(0.75 * WindowSize.x - 0.002 * (Y - 0.5 * WindowSize.y) * (Y - 0.5 * WindowSize.y))

func _draw():
	# NOTE(hugo) : This is DEBUG code to see the homeline of each fighter
	# {
	var WindowSize = get_viewport().get_rect().size
	draw_line(Vector2(FighterMargin, 0), Vector2(FighterMargin, WindowSize.y), Color(255, 0, 0), 2)
	draw_line(Vector2(WindowSize.x - FighterMargin, 0), Vector2(WindowSize.x - FighterMargin, WindowSize.y), Color(255, 0, 0), 2)
	# }
	
	# NOTE(hugo): Drawing deathline
	var WindowSize = get_viewport().get_rect().size
	var StepCount = 100
	var Epsilon = WindowSize.y / StepCount
	for StepIndex in range(StepCount):
		var YBeginning = StepIndex * Epsilon
		var YEnd = (StepIndex + 1) * Epsilon
		var XBeginning = deathline_equation(YBeginning, WindowSize)
		var XEnd = deathline_equation(YEnd, WindowSize)
		draw_line(Vector2(XBeginning, YBeginning), Vector2(XEnd, YEnd), Color(236, 88, 0), 1)

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

	Fighter.add_to_group("Fighters")
	Fighter2.add_to_group("Fighters")

	DamageCounter = find_node("DamageCounter")

	# NOTE(hugo) : Setting the left zone of the left fighter
	LeftLifeAreaNode = find_node("LeftLifeArea")
	var LeftLifeAreaShape = LeftLifeAreaNode.find_node("CollisionShape2D").get_shape()
	var LeftLifeAreaPoints = Vector2Array()
	LeftLifeAreaPoints.append(Vector2(0, 0))
	var StepCount = 100
	var Epsilon = WindowSize.y / StepCount
	for StepIndex in range(StepCount):
		var Y = StepIndex * Epsilon
		var X = deathline_equation(Y, WindowSize)
		LeftLifeAreaPoints.append(Vector2(X, Y))
	LeftLifeAreaPoints.append(Vector2(0, WindowSize.y))
	LeftLifeAreaShape.set_points(LeftLifeAreaPoints)

	LeftLifeAreaNode.add_to_group(Fighter.CollisionIgnoreGroupName)
	LeftLifeAreaNode.connect("body_exit", self, "reset_fighter")


# NOTE(hugo) : For now, this function is only used if EnableDebugTools = true.
# If you want to use this function for non-debug purposes, you might want to change
# set_process() in _ready.
func _process(dt):
	if(Input.is_key_pressed(KEY_SPACE)):
		DamageCounter.set_text(str(0))
		emit_signal("reset_damage", 0)

func respawn_hitbox():
	var LeftHitboxExists = LeftHitboxWeakRef.get_ref()
	if (!LeftHitboxExists):
		instanciate_left_hitbox()

	var RightHitboxExists = RightHitboxWeakRef.get_ref()
	if (!RightHitboxExists):
		instanciate_right_hitbox()

func update_damage_counter(FighterName, Damage):
	if(FighterName == 'Fighter'):
		DamageCounter.set_text(str(Damage))

func reset_fighter(Fighter):
	if(Fighter.is_in_group("Fighters")):
		Fighter.set_pos(Fighter.InitPos)
		Fighter.Damage = 0
		update_damage_counter(Fighter.get_name(), 0)
