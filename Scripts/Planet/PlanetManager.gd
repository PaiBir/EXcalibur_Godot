class_name PlanetManager
extends Node

@export_category("Planet Properties")
@export_group("Technical")
@export var points : Array[PlanetDataPoint]; 
var currentMesh : Mesh
@export_group("Scientific")
@export_range(0.0,10.0,0.1,"suffix:days") var orbitSpeed: float = 1
@export_range(0.1,100,0.1,"suffix:AU") var distance: float = 1

@export_category("Sphere Source") #Planet visualization and generation
@export var TechnicalAspects : PlanetTechnical
@export var subdivLevel: int = 0
var prevSubdivLevel: int = -1
@export var PlanetMat: Material
@onready var planetMesh : MeshInstance3D = $Display

@export_category("Root")
@export var Boss: Worldbase

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	planetMesh.material_override = PlanetMat


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	planetMesh.rotate(Vector3.UP,delta*orbitSpeed)
	if(prevSubdivLevel != subdivLevel):
		if(subdivLevel > TechnicalAspects.Subdivisions.size()-1):
			subdivLevel = TechnicalAspects.Subdivisions.size()-1
		elif(subdivLevel < 0):
			subdivLevel = 0
		planetMesh.mesh = TechnicalAspects.Subdivisions[subdivLevel]
		prevSubdivLevel = subdivLevel

func EnergyBalance():
	pass

func ChemicalBalance():
	pass
