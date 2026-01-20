extends Panel

@export_exp_easing var FadeInLogo
@export_exp_easing var FadeOutBG
@export_exp_easing var FadeOutLogo

var timer : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if(timer <= 2):
		print(pow(timer/2.0,FadeInLogo))
		get_child(0).modulate = Color(1.0,1.0,1.0,pow(timer/2.0,FadeInLogo))
	elif(timer <= 4):
		get_child(0).modulate = Color(1.0,1.0,1.0,1-pow((timer/2.0)-1.0,FadeOutLogo))
		print(1-pow(timer-2,FadeOutLogo))
		modulate = Color(1.0,1.0,1.0,1-pow((timer/2.0)-1.0,FadeOutBG))
	else:
		get_child(0).queue_free()
		self.queue_free()
		
