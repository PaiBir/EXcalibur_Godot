#DEPRECIATED
class_name ModelLayer
extends Node

enum LayerType {
	EMPTY,
	HYDRO,
	AERO,
	GEO
}

var world : PlanetManager
var place : PlanetDataPoint

var ModelType : LayerType
var LowerBound : float
var UpperBound : float

var Changes : Array[Dictionary]

var recievedEnergy : float = 0
#AERO model
var pressure : float = 1
var cloudcover : float = 0 #should never be more than 1
var sigma : float = 0 #between 0 and 1
var atmosphere : Array[AtmoGas]

func _init(WorldData : PlanetManager, layerPlace : PlanetDataPoint) -> void:
	world  = WorldData
	place = layerPlace

func step(timescale : PlanetDataPoint.timescale, timestep : float):
	var change : Dictionary
	if (ModelType == LayerType.EMPTY):
		pass
	if (ModelType == LayerType.GEO):
		pass
	if (ModelType == LayerType.AERO):
		var sWave = cos((2 * place.SphericalCoordinate.x)-PI) * ((world.Boss.starLuminosity / pow(world.distance, 2)) * Constants.SolarConstant)
		var a0 = minf(1, 0.085 - (0.247 * (log(world.PressureAtSeaLevel / pressure)/log(10))))
		var ac = 1 - ((1 - a0) / (1 - world.CloudAlbedo))
		var ReflectedClear = sWave * (((1 - world.GlobalAtmoAlbedo) * (1 - a0)) / (1 - (a0 * world.GlobalAtmoAlbedo)))
		var ReflectedCloudy = sWave * (((1 - world.GlobalAtmoAlbedo) * (1 - ac)) / (1 - (ac * world.GlobalAtmoAlbedo)))
		change["ShortwaveEnergy"] = (sWave - ((cloudcover * ReflectedCloudy) + ((1 - cloudcover) * ReflectedClear))) * place.calcAlbedo()
		#change["LongwaveEnergy"] = 
	Changes.append(change)


func apply():
	for change in Changes:
		if change.has("ShortwaveEnergy"):
			if (ModelType == LayerType.AERO):
				recievedEnergy += change["ShortwaveEnergy"]
