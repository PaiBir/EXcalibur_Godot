class_name CELL
extends Node

##ATMOSPHERIC MODEL
#Position of point in 3D space for visualization
var Real_Position : Vector3 = Vector3.ZERO
#Latitude & Longitudinal position of point
var LatLong : Vector2 = Vector2(0.5,0.5)
#1 component of a vector for coriolis
var Coriolis_Effect : float = 0
#The same thing as Coriolis_Effect, but... not?
var Coriolis_Effect_Fast : float = 0
#Edge of the atmosphere
var Planetary_Boundary_Layer : float = 0
#I have no clue what the K-indicies actually are, air speed?
var K_Index_Effective : float = 0 #"k-index for vertical velocity for clouds", whatever that means?
var K_Index_Terrain : float = 0
#Something with the surface?
var ZS : Array[float] = []
#Height of the surface of the planet
var Surface : float = 0
#Smoothed height of the surface of the planet
var Surface_Smooth : float = 0
#The elevation change around the point
var Slope : float = 0
#Atmospheric Pressure at the surface
var Pressure_At_Surface : float = 0
#Atmospheric Pressure at the smoothed surface
var Pressure_At_Surface_Smooth : float = 0
#Surface Air Density
var Surface_Air_Density : float = 0
#No clue
var ra2a : float = 0
var ra2 : Array[float] = []
var ps : float = 0

func _init(realPos : Vector3, latlon : Vector2) -> void:
	Real_Position = realPos
	LatLong = latlon
