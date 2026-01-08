class_name Bezier
extends Resource

@export_category("Points")
@export var pointA: Vector2
@export var pointB: Vector2
@export var pointC: Vector2
@export var pointD: Vector2

var xBound1: float
var xBound2: float

func _init(a: Vector2 = Vector2.ZERO, b: Vector2 = Vector2.ZERO, c: Vector2 = Vector2.ZERO, d: Vector2 = Vector2.ZERO) -> void:
	pointA = a
	pointB = b
	pointC = c
	pointD = d
	xBound1 = pointA.x
	xBound2 = pointD.x

func sampleCurve(Point: float) -> float:
	var time = (Point - xBound1) / (xBound2 - xBound1)
	
	var Lerp1 = V2lerp(pointA,pointB,time)
	var Lerp2 = V2lerp(pointB,pointC,time)
	var Lerp3 = V2lerp(pointC,pointD,time)
	var Lerp4 = V2lerp(Lerp1,Lerp2,time)
	var Lerp5 = V2lerp(Lerp2,Lerp3,time)
	return V2lerp(Lerp4,Lerp5,time).y


func V2lerp(pointa : Vector2, pointb : Vector2, t : float):
	return Vector2(
		((pointb.x-pointa.x)*t)+pointa.x,
		((pointb.y-pointa.y)*t)+pointa.y,
	)
