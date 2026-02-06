class_name GRID
extends Node

var MeshTris : Array[Array] = []
@export var GridInit : PlanetTechnical;
@export var subdivLevel : int = 0;

var OutputArray : Array[CELL] = []

enum GridType {
	ATMOSPHERIC,
	NONE
}

func _ready() -> void:
	pass
#FIGURE OUT OCEAN BASINS

func climber_grid_init(instanceType : GridType):
	var MM := MeshDataTool.new()
	MM.create_from_surface(GridInit.Subdivisions[subdivLevel], 0)
	for face in range(0,MM.get_face_count()):
		MeshTris.append([MM.get_face_vertex(face,0),MM.get_face_vertex(face,1),MM.get_face_vertex(face,2)])
	for vertex in range(0,MM.get_vertex_count()):
		var vertPos = MM.get_vertex(vertex)
		var c : CELL
		#Do I use just the normal vector of a given point to determine solar energy, and leave out spherical and lat/long coordinates?
		if instanceType == GridType.NONE:
			c = CELL.new(vertPos,Constants.SphericalToLatLong(Constants.CartesiantUVSpherical(vertPos)))
		elif instanceType == GridType.ATMOSPHERIC:
			c = ATM_CELL.new(vertPos,Constants.SphericalToLatLong(Constants.CartesiantUVSpherical(vertPos)))
		OutputArray.append(c)
