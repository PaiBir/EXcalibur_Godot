extends Node

static var StefanBoltzmanConstant: float = 5.67037e-8 #W/M^2K^4
static var graviationalConstant : float = 6.667e-11 #Newtons per m&2/kg^2
static var SunDiameter := 6.957e8
static var AUdefiniton := 149597870700
static var SolarConstant := 1370 #Wm^2
static var EarthDiameter := 12756 #km
static var EarthMass := 59.8e23 #kg

#Derived from David A. Randall et. al. (2002)
static var basePointDistEarth = 3717.4

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

# CLIMBER_X
static var density_ice := 910.0 #kg/m^3
static var density_water := 1000.0 #kg/m^3
static var density_seawater := 1028.0 #kg/m^3
static var density_asthenosphere := 3.3e3 #kg/m^3

static var heatcapacity_air := 1000 #J/kg/K
static var heatcapacity_ice := 2110 #J/kg/K
static var heatcapacity_water := 4187 #J/kg/K

static var thermalconductivity_air := 0.023 #W/m/K
static var thermalconductivity_ice := 2.2 #W/m/K
static var thermalconductivity_water := 0.6 #W/m/K

static var emis_snow := 0.99 #"longwave emissivity of water, presumably how much recieved energy is released as longwave radiation
static var emis_water := 0.98 #"longwave emissivity of water, presumably how much recieved energy is released as longwave radiation

static var LatentHeatofEvaporation := 2501e3 #J/kg
static var LatentHeatofFusion := 334e3 #J/kg
static var LatentHeatofSublimation := LatentHeatofEvaporation + LatentHeatofFusion #J/kg

static var specificGasConstant_dryair := 287.058 #J/kg/K
static var specificGasConstant_watervapor := 461.5 #J/kg/K

static var EarthAngularVelocity := 7.2921e-5 #l/s (I have no clue what unit l is)

static var karman = 0.4 #von Karman constant

static var ZeroCelsius = 273.15

#Bibliography
# Randall, D. A.; Ringler, T. D.; Heikes, R. P.; Jones, P.; Baumgardner, J. Climate Modeling with Spherical Geodesic Grids. Computing in Science & Engineering 2002, 4 (5), 32–41. https://doi.org/10.1109/MCISE.2002.1032427.

func FQSAT_sp (T : float, p: float) -> float: #Not entirely sure what this function is *doing*
	var Ti : float = 248
	var r_w : float = 0
	if(T > ZeroCelsius):
		r_w = 1
	elif ((T > Ti) and (T < ZeroCelsius)):
		r_w = 1 - ((ZeroCelsius - T) / (ZeroCelsius - Ti))
	else:
		r_w = 0
	
	var qsatw = 380.0047 * exp( 17.625 * (T - ZeroCelsius) / (T - 30.11)) / p # Pascals, water
	var qsati = 380.1726 * exp( 22.587 * (T - ZeroCelsius) / (T + 0.71)) / p # Pascals, ice
	return ((r_w * qsatw) + ((1 - r_w) * qsati))
