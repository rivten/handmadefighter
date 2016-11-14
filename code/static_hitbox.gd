extends Area2D

func _ready():
	set_process(true)
	
func _process(delta):
	if (get_overlapping_bodies() != []):
		self.queue_free()
