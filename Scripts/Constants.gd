extends Node

var StefanBoltzmanConstant: float = 5.67037e-8 #W/M^2K^4

var SunDiameter = 6.957e8
var AUdefiniton = 149597870700

func ConvertCartesianToSpherical(points : Array[Vector3]) -> Array[Vector2]:
	var sPoints : Array[Vector2] = []
	for point in points:
		var sPoint = Vector2.ZERO
		#THETA (x)
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
		elif point.x == 0 and point.z > 0:
			sPoint.y = PI / 2
		elif point.x == 0 and point.z < 0:
			sPoint.y = -PI / 2
		else:
			sPoint.y = 0
		
		#Assign
		sPoints.append(sPoint)
	return sPoints
