extends Area2D

func _ready():
	set_fixed_process(true)
	
func _fixed_process(delta):
	if (!get_overlapping_bodies().empty()):
		self.queue_free()
