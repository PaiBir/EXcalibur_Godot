extends Node

static var StefanBoltzmanConstant: float = 5.67037e-8 #W/M^2K^4
static var SunDiameter := 6.957e8
static var AUdefiniton := 149597870700
static var SolarConstant := 1370 #Wm^2
static var EarthDiameter := 12756 #km

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

static var gases : Array[Dictionary] = [ #Needs sources
	#EARTH
	{"Name": "Nitrogen", "Weight":0}, 
	{"Name": "Atmoic Oxogen", "Weight":0},
	{"Name": "Molecular Oxygen", "Weight":0},
	{"Name": "Helium", "Weight":0},
	{"Name": "Argon", "Weight":0},
	{"Name": "Atomic Hydrogen", "Weight":0},
	{"Name": "Neon", "Weight":0},
	{"Name": "Krypton", "Weight":0},
	{"Name": "Xenon", "Weight":0},
	{"Name": "Nitrous Oxide", "Weight":0},
	{"Name": "Nitric Oxide", "Weight":0},
	{"Name": "Nitrogen Dioxide", "Weight":0},
	{"Name": "Hydrogen Sulfide", "Weight":0},
	{"Name": "Ammonia", "Weight":0},
	{"Name": "Molecular Hydrogen", "Weight":0},
	{"Name": "Methane", "Weight":0},
	{"Name": "Sulfur Dioxide", "Weight":0},
	{"Name": "Carbon Monoxide", "Weight":0},
	{"Name": "Carbon Dioxide", "Weight":0},
	{"Name": "Ozone", "Weight":0},
	
	#MARS
	
	#VENUS
	
	#TITAN
	
]
