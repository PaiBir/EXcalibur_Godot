class_name PlanetDataPoint
extends Node

var MeshIndex : int = -1
var SphericalCoordinate : Vector2
#Expand as neccesary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _init(index : int) -> void:
	MeshIndex = index
