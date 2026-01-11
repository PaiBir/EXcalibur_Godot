extends LineEdit

@export var Files : FileDialog;

func openDialog():
	Files.visible = true

func set_path(dir : String):
	text = dir
