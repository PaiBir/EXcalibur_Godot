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

func _init(WorldData : PlanetManager, layerPlace : PlanetDataPoint) -> void:
	world  = WorldData
	place = layerPlace

func step(timescale : PlanetDataPoint.timescale, timestep : float):
	var change : Dictionary
	if (ModelType == LayerType.EMPTY):
		pass
	if (ModelType == LayerType.GEO):
		if(recievedEnergy == 0):
			change["Energy"] = (1.0 - place.albedo) * ((world.Boss.starLuminosity / pow(world.distance, 2)) * Constants.SolarConstant)
	

func apply():
	for change in Changes:
		if change.has("Energy"):
			recievedEnergy += change["Energy"]
