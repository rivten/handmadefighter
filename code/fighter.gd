
extends KinematicBody2D

export var AccelerationNorm = 6000
export var Drag = 10
var Velocity = Vector2(0, 0)
var InitPos = Vector2(0, 0)
var DrawLeft = false
var DrawRight = false
var Freezed = false

export(Vector2) var BulletVelocity = Vector2(90.0, 0.0)

func _draw():
	var LeftAreaNodeRect = find_node("LeftArea").get_item_rect()
	var RightAreaNodeRect = find_node("RightArea").get_item_rect()
	LeftAreaNodeRect.size.y = 0.5 * LeftAreaNodeRect.size.y
	RightAreaNodeRect.pos = LeftAreaNodeRect.pos + Vector2(0, LeftAreaNodeRect.size.y)
	RightAreaNodeRect.size.y = 0.5 * RightAreaNodeRect.size.y
	if(DrawRight):
		self.draw_rect(RightAreaNodeRect, Color(1.0, 0.0, 0.0, 1.0))
	else:
		self.draw_rect(RightAreaNodeRect, Color(0.0, 1.0, 0.0, 1.0))

	if(DrawLeft):
		self.draw_rect(LeftAreaNodeRect, Color(1.0, 0.0, 0.0, 1.0))
	else:
		self.draw_rect(LeftAreaNodeRect, Color(0.0, 1.0, 0.0, 1.0))

func _ready():
	set_fixed_process(true)
	set_pos(InitPos)

	Freezed = false
	var LeftAreaNode = find_node("LeftArea")
	var RightAreaNode = find_node("RightArea")
	LeftAreaNode.connect("area_enter", self, "hit_left_area")
	RightAreaNode.connect("area_enter", self, "hit_right_area")
	var FreezeTimerNode = find_node("FreezeTimer")
	FreezeTimerNode.connect("timeout", self, "end_freeze")

func shoot():
	var Root = get_tree().get_root().get_node("Game")
	var BulletNode = preload("res://Bullet.tscn").instance()
	BulletNode.set_pos(get_pos())
	BulletNode.set_velocity(BulletVelocity)
	Root.add_child(BulletNode)

func _fixed_process(dt):
	var Acceleration = Vector2(0, 0)

	if(!Freezed):
		if(Input.is_action_pressed("up")):
			Acceleration += Vector2(0, -1)
		if(Input.is_action_pressed("down")):
			Acceleration += Vector2(0, 1)
		if(Input.is_action_pressed("right")):
			shoot()

		Acceleration *= AccelerationNorm
		Velocity += dt * Acceleration - dt * Drag * Velocity
		var DeltaPos = dt * Velocity + 0.5 * dt * dt * Acceleration

		move(DeltaPos)

	self.update()

func hit_left_area(AreaEntered):
	if(!Freezed):
		Freezed = true
		var FreezeTimerNode = find_node("FreezeTimer")
		FreezeTimerNode.start()

	if(DrawLeft):
		DrawLeft = false
	else:
		DrawLeft = true
	self.update()

func hit_right_area(AreaEntered):
	if(!Freezed):
		Freezed = true
		var FreezeTimerNode = find_node("FreezeTimer")
		FreezeTimerNode.start()

	if(DrawRight):
		DrawRight = false
	else:
		DrawRight = true
	self.update()


func end_freeze():
	Freezed = false
