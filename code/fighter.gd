
extends KinematicBody2D

# NOTE(hugo) : Input map
const INPUT_UP = 0
const INPUT_DOWN = 1
const INPUT_SHOOT = 2
var InputMap = ["", "", ""]

export var AccelerationNorm = 6000
export var Drag = 10
export var HitlagTeleportDelta = 100
export var ProjectionAccelerationNorm = 100000
var InitPos = Vector2(0, 0)
var Velocity = Vector2(0, 0)
var Acceleration = Vector2(0.0, 0.0)
var Frozen = false
var FreezeInputRecorded = false
var FreezeInput = Vector2(0.0, 0.0)
var FreezeTimerNode
var ProjectionAcceleration = Vector2(0.0, 0.0)
var LastHitSide
var IsControllable = true

var BulletDir = Vector2(1.0, 0.0)
export(float, 0.0, 150.0) var BulletSpeed = 90.0

func set_input_map(UpInput, DownInput, ShootInput):
	InputMap[INPUT_UP] = UpInput
	InputMap[INPUT_DOWN] = DownInput
	InputMap[INPUT_SHOOT] = ShootInput

func set_default_input_map():
	set_input_map("up0", "down0", "right0")

func _ready():
	set_fixed_process(true)
	set_pos(InitPos)

	Frozen = false
	FreezeInputRecorded = false
	FreezeInput = Vector2(0.0, 0.0)

	FreezeTimerNode = find_node("FreezeTimer")
	FreezeTimerNode.connect("timeout", self, "teleport_and_project")

	var LeftAreaNode = find_node("LeftArea")
	var RightAreaNode = find_node("RightArea")
	LeftAreaNode.connect("area_enter", self, "set_hit_side_to_left")
	RightAreaNode.connect("area_enter", self, "set_hit_side_to_right")

	set_default_input_map()


func _fixed_process(dt):

	if(IsControllable && (!Frozen)):
		if(Input.is_action_pressed(InputMap[INPUT_UP])):
			Acceleration += AccelerationNorm * Vector2(0, -1)
		if(Input.is_action_pressed(InputMap[INPUT_DOWN])):
			Acceleration += AccelerationNorm * Vector2(0, 1)
		if(Input.is_action_pressed(InputMap[INPUT_SHOOT])):
			shoot()

		Velocity += dt * Acceleration - dt * Drag * Velocity
		var DeltaPos = dt * Velocity + 0.5 * dt * dt * Acceleration

		Acceleration = Vector2(0.0, 0.0)
		#(K) Acceleration is reset at the end (and not the beginning) so that another 
		# function (like teleport_and_project) can decide of the acceleration for one frame
		move(DeltaPos)

	else : #NOTE(hugo) : if Freeze
		if(!FreezeInputRecorded):
			if(Input.is_action_pressed(InputMap[INPUT_UP])):
				FreezeInput = Vector2(0, -1)
				FreezeInputRecorded = true
			if(Input.is_action_pressed(InputMap[INPUT_DOWN])):
				FreezeInput = Vector2(0, 1)
				FreezeInputRecorded = true

func shoot():
	var Root = get_tree().get_root().get_node("Game")
	var BulletNode = preload("res://Bullet.tscn").instance()
	BulletNode.set_pos(get_pos())
	BulletNode.set_velocity(BulletSpeed * BulletDir)
	Root.add_child(BulletNode)

func set_hit_side_to_left(EnteredHitbox):
	EnteredHitbox.queue_free()
	if(!Frozen):
		Frozen = true
		FreezeTimerNode.start()
		LastHitSide = "left"

func set_hit_side_to_right(EnteredHitbox):
	EnteredHitbox.queue_free()
	if(!Frozen):
		Frozen = true
		FreezeTimerNode.start()
		LastHitSide = "right"

func teleport_and_project():
	#(K)Teleport…
	var DeltaFreezePos = HitlagTeleportDelta * FreezeInput;
	move(DeltaFreezePos)

	#(K)…and project
	var HitDirection
	if (LastHitSide == "left"):
		HitDirection = Vector2(0, 1)
	else: # LastHitSide == "right"
		HitDirection = Vector2(0, -1)
	Acceleration += ProjectionAccelerationNorm * HitDirection

	# NOTE(hugo): re-init of freeze parameters
	FreezeInput = Vector2(0, 0)
	Frozen = false
	FreezeInputRecorded = false
