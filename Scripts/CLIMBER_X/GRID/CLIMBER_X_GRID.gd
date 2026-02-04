class_name GRID
extends Node

var MeshTris : Array[Array] = []
@export var GridInit : PlanetTechnical;
@export var subdivLevel : int = 0;

var OutputArray : Array[CELL] = []

func _ready() -> void:
	pass
#FIGURE OUT OCEAN BASINS

func climber_grid_init():
	var MM := MeshDataTool.new()
	MM.create_from_surface(GridInit.Subdivisions[subdivLevel], 0)
	for face in range(0,MM.get_face_count()):
		MeshTris.append([MM.get_face_vertex(face,0),MM.get_face_vertex(face,1),MM.get_face_vertex(face,2)])
	for vertex in range(0,MM.get_vertex_count()):
		var vertPos = MM.get_vertex(vertex)
		#Do I use just the normal vector of a given point to determine solar energy, and leave out spherical and lat/long coordinates?
		var c = CELL.new(vertPos,Constants.SphericalToLatLong(Constants.CartesiantUVSpherical(vertPos)))
		OutputArray.append(c)
