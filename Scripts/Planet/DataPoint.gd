class_name PlanetDataPoint
extends Node

var MeshIndex : int = -1
var SphericalCoordinate : Vector2
var height : float;
var color : Color;
#Expand as neccesary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _init(index : int, pos : Vector3, pColor : Color = Color.BLACK) -> void:
	MeshIndex = index
	SphericalCoordinate = CartesiantUVSpherical(pos)
	color = pColor
	
func CartesiantUVSpherical(point : Vector3) -> Vector2: #Based off of the conversion math here (https://en.wikipedia.org/wiki/Spherical_coordinate_system#Coordinate_system_conversions)
	var sPoint = Vector2.ZERO
	if point.y > 0:
		sPoint.x = atan(sqrt((point.x * point.x) + (point.z * point.z)) / point.y)
	elif point.y <  0:
		sPoint.x = PI + atan(sqrt((point.x * point.x) + (point.z * point.z)) / point.y)
	elif point.y == 0 and sqrt((point.x * point.x) + (point.z * point.z)) != 0:
		sPoint.x = PI / 2
	else:
		sPoint.x = 0
	
	#PSI (y)
	if point.x > 0:
		sPoint.y = atan(point.z/point.x)
	elif point.x < 0 and point.z >= 0:
		sPoint.y = atan(point.z/point.x) + PI
	elif point.x < 0 and point.z < 0:
		sPoint.y = atan(point.z/point.x) - PI
	elif point.x == 0 and point.z > 0:
		sPoint.y = PI / 2
	elif point.x == 0 and point.z < 0:
		sPoint.y = -PI / 2
	else:
		sPoint.y = 0
	
	return Vector2(sPoint.x,sPoint.y)

func SphericalToLatLong(pos : Vector2) ->Vector2:
	return Vector2((pos.x) / ((2 * PI)/360), ((pos.y + (PI / 2.0))) / (PI/180))
