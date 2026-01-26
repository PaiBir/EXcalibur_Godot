#DEPRECIATED
class_name PlanetDataPoint
extends Node

enum timescale {
	hour,
	day,
	month,
	year
}

var MeshIndex : int = -1
var SphericalCoordinate : Vector2
var height : float;
var color : Color;
var Terrain : Array[ModelLayer];
var world : PlanetManager
#Expand as neccesary

func _init(worldParent : PlanetManager, index : int, pos : Vector3, pColor : Color = Color.BLACK) -> void:
	MeshIndex = index
	SphericalCoordinate = Constants.CartesiantUVSpherical(pos)
	color = pColor
	world = worldParent
	for i in range(0,worldParent.layers.size()):
		var newLayer = ModelLayer.new(worldParent,self)
		#newLayer.recievedEnergy = (1.0 - calcAlbedo()) * ((worldParent.Boss.starLuminosity / pow(worldParent.distance, 2)) * Constants.SolarConstant)
		newLayer.recievedEnergy = 0
		Terrain.append(newLayer)
		Terrain[i].ModelType = worldParent.layers[i]

func iterate(_timescale : timescale, timestep : float):
	for layer in Terrain:
		layer.step(_timescale, timestep)

func apply():
	for layer in Terrain:
		layer.apply()

func calcAlbedo() -> float:
	return (color.r + color.g + color.b)/3.0

func sumEnergy() -> float:
	var energy : float = 0
	for layer in Terrain:
		energy += layer.recievedEnergy
	return energy
