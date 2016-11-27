
extends KinematicBody2D

# NOTE(hugo) : Input map
const INPUT_UP = 0
const INPUT_DOWN = 1
const INPUT_SHOOT = 2
const INPUT_SPECIAL = 3
var InputMap = ["", "", "", ""]

export var AccelerationNorm = 6000
export var Drag = 10
export var HitlagTeleportDelta = 100
export var ProjectionAccelerationNorm = 100000
export(float, 0.0, 2.0, 0.01) var CooldownDuration = 0.2
var InitPos = Vector2(0, 0)
var Velocity = Vector2(0, 0)
var Acceleration = Vector2(0.0, 0.0)
var Frozen = false
var FreezeInputRecorded = false
var FreezeInput = Vector2(0.0, 0.0)
var FreezeTimerNode
var CooldownTimerNode
var ProjectionAcceleration = Vector2(0.0, 0.0)
var LastHitSide
var IsControllable = true
var CanShoot = true
var BulletScene = preload("res://Bullet.tscn")
var BulletsGroupName
var BulletDir = Vector2(1.0, 0.0)
export(float, 0.0, 150.0) var BulletSpeed = 90.0

signal hit_by_hitbox

func set_input_map(UpInput, DownInput, ShootInput, SpecialInput):
	InputMap[INPUT_UP] = UpInput
	InputMap[INPUT_DOWN] = DownInput
	InputMap[INPUT_SHOOT] = ShootInput
	InputMap[INPUT_SPECIAL] = SpecialInput

func set_default_input_map():
	set_input_map("up0", "down0", "right0", "control0")

func _ready():
	set_fixed_process(true)
	set_pos(InitPos)

	Frozen = false
	FreezeInputRecorded = false
	FreezeInput = Vector2(0.0, 0.0)

	FreezeTimerNode = find_node("FreezeTimer")
	FreezeTimerNode.connect("timeout", self, "teleport_and_project")

	CooldownTimerNode = find_node("CooldownTimer")
	CooldownTimerNode.connect("timeout", self, "enable_shooting")

	BulletsGroupName = "BulletsOf" + self.get_name()

	var LeftAreaNode = find_node("LeftArea")
	var RightAreaNode = find_node("RightArea")
	LeftAreaNode.connect("area_enter", self, "set_hit_side_to_left")
	RightAreaNode.connect("area_enter", self, "set_hit_side_to_right")

	set_default_input_map()

	var GameNode = get_node("/root/Game")
	self.connect("hit_by_hitbox", GameNode, "increase_damage_counter")

func _fixed_process(dt):

	if(IsControllable && (!Frozen)):
		if(Input.is_action_pressed(InputMap[INPUT_UP])):
			Acceleration += AccelerationNorm * Vector2(0, -1)
		if(Input.is_action_pressed(InputMap[INPUT_DOWN])):
			Acceleration += AccelerationNorm * Vector2(0, 1)
		if(Input.is_action_pressed(InputMap[INPUT_SHOOT]) && CanShoot):
			shoot()
			CanShoot = false
			CooldownTimerNode.set_wait_time(CooldownDuration)
			CooldownTimerNode.start()

		Velocity += dt * Acceleration - dt * Drag * Velocity
		var DeltaPos = dt * Velocity + 0.5 * dt * dt * Acceleration

		Acceleration = Vector2(0.0, 0.0)
		var PreviousPos = get_pos()
		#(K) Acceleration is reset at the end (and not the beginning) so that another 
		# function (like teleport_and_project) can decide of the acceleration for one frame
		move(DeltaPos)

		if(Input.is_action_pressed(InputMap[INPUT_SPECIAL])):
			# NOTE(hugo) : I need to compare with the previous position in case a movement is asked by the
			# user but cannot be resolved by the collision manager. For example, I want to go down but
			# cannot because of the screen. DeltaPos is not null but the resulting movement is, therefore 
			# the need to compare the previous position with the actual resulting position after the 
			# 'move' call
			var ActualMovement = get_pos() - PreviousPos
			var DeltaPosVerticalComponent = Vector2(0, ActualMovement.y)
			var BulletGroup = get_tree().get_nodes_in_group(BulletsGroupName)
			for Bullet in BulletGroup:
				Bullet.set_pos(Bullet.get_pos() + DeltaPosVerticalComponent)

	else : #NOTE(hugo) : if Freeze
		if(!FreezeInputRecorded):
			if(Input.is_action_pressed(InputMap[INPUT_UP])):
				FreezeInput = Vector2(0, -1)
				FreezeInputRecorded = true
			if(Input.is_action_pressed(InputMap[INPUT_DOWN])):
				FreezeInput = Vector2(0, 1)
				FreezeInputRecorded = true
	
func shoot():
	var GameNode = get_tree().get_root().get_node("Game")
	var BulletNode = BulletScene.instance()
	BulletNode.set_pos(get_pos())
	BulletNode.set_velocity(BulletSpeed * BulletDir)
	GameNode.add_child(BulletNode)
	BulletNode.add_to_group(BulletsGroupName)

func enable_shooting():
	CanShoot = true

func set_hit_side_to_left(EnteredHitbox):
	if(!EnteredHitbox.is_in_group(BulletsGroupName)):
		EnteredHitbox.queue_free()
		if(!Frozen):
			Frozen = true
			FreezeTimerNode.start()
			LastHitSide = "left"
			emit_signal("hit_by_hitbox", self.get_name(), 10)

func set_hit_side_to_right(EnteredHitbox):
	if(!EnteredHitbox.is_in_group(BulletsGroupName)):
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
