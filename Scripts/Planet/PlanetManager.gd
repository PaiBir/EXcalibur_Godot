class_name PlanetManager
extends Node

@export_category("Planet Properties")
@export_group("Technical")
@export var points : Array[PlanetDataPoint]; 
var currentMesh : Mesh
var thrd : Array[Thread]
var sem : Semaphore
@export var numThreads : int = 11 #10 main, 1 remainder
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
	sem = Semaphore.new()
	for i in range(0,numThreads):
		thrd.append(Thread.new())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	planetMesh.rotation = Vector3(tilt*((2.0*PI)/360.0),(0.5/DaysSpeed) * (Time.get_ticks_msec() * rotMod),0.0)
	if(prevSubdivLevel != subdivLevel):
		if(subdivLevel > TechnicalAspects.Subdivisions.size()-1):
			subdivLevel = TechnicalAspects.Subdivisions.size()-1
		elif(subdivLevel < 0):
			subdivLevel = 0
		points.clear()
		MeshManipulator.create_from_surface(TechnicalAspects.Subdivisions[subdivLevel], 0)
		for index in range(0,MeshManipulator.get_vertex_count()):
			MeshManipulator.set_vertex_color(index,Color(randf(), randf(), randf(), 1))
			points.append(PlanetDataPoint.new(index,MeshManipulator.get_vertex(index)))
		var commitmesh = ArrayMesh.new()
		MeshManipulator.commit_to_surface(commitmesh)
		planetMesh.mesh = commitmesh
		prevSubdivLevel = subdivLevel

func EnergyBalance():
	pass

func ChemicalBalance():
	pass

func SetTex(role : int, img : ImageTexture):  #0: Color, 1: Height, 2: Full spectrum Albedo
	var pointsPerThread : int = floor(points.size() / (numThreads-1))
	var pointMin : int = 0
	for thred in thrd:
		thred.start(_threadsSetTex.bind(role,img,pointMin,max(pointMin+pointsPerThread-1,points.size()-1)))
		pointMin += pointsPerThread
	var CanContinue : bool = false
	while  CanContinue == false:
		CanContinue = true
		for thred in thrd:
			if thred.is_alive():
				CanContinue = false
	for ClimateNode in points:
		MeshManipulator.set_vertex_color(ClimateNode.MeshIndex,ClimateNode.color)
	var commitmesh = ArrayMesh.new()
	MeshManipulator.commit_to_surface(commitmesh)
	planetMesh.mesh = commitmesh

func _threadsSetTex(role : int, img : ImageTexture, lwrbound : int, uprbound : int):
	for i in range(lwrbound,uprbound+1):
		print(" ")
		print(points[i].SphericalCoordinate)
		print(points[i].SphericalToLatLong(points[i].SphericalCoordinate))
		print(img.get_size())
		print(((points[i].SphericalToLatLong(points[i].SphericalCoordinate)/Vector2(360,360))+Vector2(0,0.5)) * img.get_size())
		if(role == 0):
			points[i].color = img.get_image().get_pixelv(points[i].SphericalCoordinate * img.get_size())
		elif (role == 1):
			points[i].height = img.get_image().get_pixelv(points[i].SphericalCoordinate * img.get_size()).r
