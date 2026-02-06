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

func _init(realPos : Vector3, latlon : Vector2) -> void:
	Real_Position = realPos
	LatLong = latlon
