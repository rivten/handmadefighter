
extends Area2D

var Velocity = Vector2(0.0, 0.0)

func _ready():
	set_fixed_process(true)

func _fixed_process(dt):
	self.set_pos(self.get_pos() + dt * Velocity)

func set_velocity(V):
	self.Velocity = V

