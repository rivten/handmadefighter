
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
export(float, 0.0, 2.0, 0.01) var CooldownDuration = 0.2
export(float, 0.0, 500.0, 10.0) var HomelineAttractionSpeed = 1.0
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

# NOTE(hugo) : Shoot data
# {
const BULLET_TYPE_FAST = 0
const BULLET_TYPE_STRONG = 1
var CanShoot = true
var BulletScene = preload("res://Bullet.tscn")
var BulletsGroupName
var BulletDir = Vector2(1.0, 0.0)
export(float, 0.0, 150.0) var BulletSpeed = 90.0
export(int, "BULLET_TYPE_FAST", "BULLET_TYPE_STRONG") var BulletType = 0
# }

signal hit_by_hitbox

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

	CooldownTimerNode = find_node("CooldownTimer")
	CooldownTimerNode.connect("timeout", self, "enable_shooting")

	BulletsGroupName = "BulletsOf" + self.get_name()

	var LeftAreaNode = find_node("LeftArea")
	var RightAreaNode = find_node("RightArea")
	LeftAreaNode.connect("area_enter", self, "start_hitlag_from_left")
	RightAreaNode.connect("area_enter", self, "start_hitlag_from_right")

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
			shoot(BulletType)
			CanShoot = false
			CooldownTimerNode.set_wait_time(CooldownDuration)
			CooldownTimerNode.start()

		var HomelineAttractionVelocity = Vector2(0, 0)
		var DirectionOfHomeline = Vector2(InitPos.x - get_pos().x, 0.0).normalized()
		if(DirectionOfHomeline.dot(BulletDir) < 0):
			HomelineAttractionVelocity = HomelineAttractionSpeed * DirectionOfHomeline
		else:
			# NOTE(hugo) : If we are behind the homeline, just set the x coordinates to the homeline
			set_pos(Vector2(InitPos.x, get_pos().y))
		Velocity += dt * (Acceleration - Drag * Velocity) + HomelineAttractionVelocity
		var DeltaPos = dt * (Velocity + 0.5 * dt * Acceleration);

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
	
func shoot(BulletType):
	var GameNode = get_tree().get_root().get_node("Game")
	var BulletNode = BulletScene.instance()
	BulletNode.set_pos(get_pos())
	BulletNode.set_name("Bullet")

	var BulletVelocity
	var BulletPower
	# NOTE(hugo) : There are still no switch statement in Godot for now :(
	if(BulletType == BULLET_TYPE_FAST):
		BulletVelocity = BulletSpeed * BulletDir
		BulletPower = 10

	elif(BulletType == BULLET_TYPE_STRONG):
		BulletVelocity = 0.5 * BulletSpeed * BulletDir
		BulletPower = 20

	else:
		assert(false) #NOTE(hugo) : Invalid default case

	BulletNode.Velocity = BulletVelocity
	BulletNode.Power = BulletPower
	GameNode.add_child(BulletNode)
	BulletNode.add_to_group(BulletsGroupName)

func enable_shooting():
	CanShoot = true

func start_hitlag_from_left(EnteredHitbox):
	start_hitlag(EnteredHitbox, "left")

func start_hitlag_from_right(EnteredHitbox):
	start_hitlag(EnteredHitbox, "right")

func start_hitlag(EnteredHitbox, HitSide):
	var Damage = 0
	if(!EnteredHitbox.is_in_group(BulletsGroupName)):
		#NOTE(hugo): I don't really like that but I don't see any easy way around this. We need to get the power of a bullet, so we need to know if we hit a bullet first, then react accordingly
		if(EnteredHitbox.get_name() == "Bullet"):
			Damage = EnteredHitbox.Power
		EnteredHitbox.queue_free()
		if(!Frozen):
			Frozen = true
			FreezeTimerNode.start()
			LastHitSide = HitSide
			emit_signal("hit_by_hitbox", self.get_name(), Damage)

func teleport_and_project():
	#(K)Teleport…
	var DeltaFreezePos = HitlagTeleportDelta * FreezeInput
	move(DeltaFreezePos)

	#(K)…and project
	var HitDirection
	if (LastHitSide == "left"):
		HitDirection = Vector2(0, 1) + 0.5 * BulletDir
	else: # LastHitSide == "right"
		HitDirection = Vector2(0, -1) + 0.5 * BulletDir
	Acceleration += ProjectionAccelerationNorm * HitDirection

	# NOTE(hugo): re-init of freeze parameters
	FreezeInput = Vector2(0, 0)
	Frozen = false
	FreezeInputRecorded = false
