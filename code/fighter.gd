
extends Node2D

export var AccelerationNorm = 6000
export var Drag = 10
var Velocity = Vector2(0, 0)
var InitPos = Vector2(0, 0)

func _ready():
	set_fixed_process(true)
	set_pos(InitPos)

func _fixed_process(dt):
	var Acceleration = Vector2(0, 0)

	if(Input.is_action_pressed("up")):
		Acceleration += Vector2(0, -1)
	if(Input.is_action_pressed("down")):
		Acceleration += Vector2(0, 1)

	Acceleration *= AccelerationNorm
	Velocity += dt * Acceleration - dt * Drag * Velocity
	var DeltaPos = dt * Velocity + 0.5 * dt * dt * Acceleration

	move(DeltaPos)


