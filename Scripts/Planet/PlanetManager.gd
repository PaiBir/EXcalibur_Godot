class_name PlanetManager
extends Node

@export_category("Planet Properties")
@export_group("Technical")
@export var points : Array[PlanetDataPoint]; 
var currentMesh : Mesh
@export var rotMod : float = 0.01;
@export_group("Scientific")
@export var DaysSpeed: float = 1 #Earth days
@export var distance: float = 1 #AU
@export var tilt: float = 22.5 #degrees
@export var YearLength: float = 365 #Planet days

@export_category("Sphere Source") #Planet visualization and generation
@export var TechnicalAspects : PlanetTechnical
@export var subdivLevel: int = 0
var prevSubdivLevel: int = -1
@export var PlanetMat: Material
@onready var planetMesh : MeshInstance3D = $Display

@export_category("Root")
@export var Boss: Worldbase

var MeshManipulator = MeshDataTool.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	planetMesh.material_override = PlanetMat
	planetMesh.rotation_order = EULER_ORDER_XZY


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	planetMesh.rotation = Vector3(tilt*((2.0*PI)/360.0),(0.5/DaysSpeed) * (Time.get_ticks_msec() * rotMod),0.0)
	if(prevSubdivLevel != subdivLevel):
		if(subdivLevel > TechnicalAspects.Subdivisions.size()-1):
			subdivLevel = TechnicalAspects.Subdivisions.size()-1
		elif(subdivLevel < 0):
			subdivLevel = 0
		MeshManipulator.create_from_surface(TechnicalAspects.Subdivisions[subdivLevel], 0)
		for index in range(0,MeshManipulator.get_vertex_count()):
			MeshManipulator.set_vertex_color(index,Color(randf(), randf(), randf(), 1))
			points.append(PlanetDataPoint.new(index))
		var commitmesh = ArrayMesh.new()
		MeshManipulator.commit_to_surface(commitmesh)
		planetMesh.mesh = commitmesh
		prevSubdivLevel = subdivLevel

func EnergyBalance():
	pass

func ChemicalBalance():
	pass
