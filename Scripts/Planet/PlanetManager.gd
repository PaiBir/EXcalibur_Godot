class_name PlanetManager
extends Node

#Technical aspects
var points : Array[PlanetDataPoint]; 
var currentMesh : Mesh
var thrd : Array[Thread]
var mut : Mutex
var Finished : int = 0
var numThreads : int = 11 #10 main, 1 remainder
var rotMod : float = 0.001;

#Planet characterisitics
var PlanetName: String = ""
var DaysSpeed: float = 1 #Earth days
var distance: float = 1 #AU
var tilt: float = 22.5 #degrees
var YearLength: float = 365 #Planet days
var PlanetMass : float = 1 #Earth Masses
var PlanetRadius : float = 1 #Earth Radii
var GlobalAtmoAlbedo : float = 0.1
var PressureAtSeaLevel : float = 1 #atm
var CloudAlbedo : float = 0.9 #Just a guess. Fill in better later

#Model visualisation and execution
@export var TechnicalAspects : PlanetTechnical
var subdivLevel: int = 0
var prevSubdivLevel: int = -1
@export var PlanetMat: Material
@onready var planetMesh : MeshInstance3D = $Display
var timescale : PlanetDataPoint.timescale = PlanetDataPoint.timescale.year
var stepsize : float = 1
var minHeight : float = -10935  #lowest point
var maxheight : float = 8848.86 #tallest point
var layers : Array[ModelLayer.LayerType] = [ModelLayer.LayerType.AERO,ModelLayer.LayerType.GEO]

@export_category("Root")
@export var Boss: Worldbase

var MeshManipulator = MeshDataTool.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	planetMesh.material_override = PlanetMat
	planetMesh.rotation_order = EULER_ORDER_XZY
	mut = Mutex.new()
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
			var PColor = Color(randf(), randf(), randf(), 1)
			MeshManipulator.set_vertex_color(index,PColor)
			points.append(PlanetDataPoint.new(self,index,MeshManipulator.get_vertex(index),PColor))
		var commitmesh = ArrayMesh.new()
		MeshManipulator.commit_to_surface(commitmesh)
		planetMesh.mesh = commitmesh
		prevSubdivLevel = subdivLevel

func forceMesh(subLevel):
	if(subLevel > TechnicalAspects.Subdivisions.size()-1):
		subLevel = TechnicalAspects.Subdivisions.size()-1
	elif(subLevel < 0):
		subLevel = 0
	subdivLevel = subLevel
	prevSubdivLevel = subLevel
	MeshManipulator.create_from_surface(TechnicalAspects.Subdivisions[subdivLevel], 0)
	if(points.size() == MeshManipulator.get_vertex_count()):
		for index in range(0,points.size()):
			MeshManipulator.set_vertex_color(points[index].MeshIndex,points[index].color)
	else:
		for index in range(0,MeshManipulator.get_vertex_count()):
			MeshManipulator.set_vertex_color(index,Color.WHITE)
	var commitmesh = ArrayMesh.new()
	MeshManipulator.commit_to_surface(commitmesh)
	planetMesh.mesh = commitmesh

func force_colors():
	if(MeshManipulator.get_vertex_count() == points.size()):
		for index in range(0,points.size()):
			MeshManipulator.set_vertex_color(points[index].MeshIndex,points[index].color)
		var commitmesh = ArrayMesh.new()
		MeshManipulator.commit_to_surface(commitmesh)
		planetMesh.mesh = commitmesh
	else:
		return

func stepModel():
	for point in points:
		point.iterate(timescale, stepsize)
	for point in points:
		point.apply()

func SetTex(role : int, img : ImageTexture):  #0: Color, 1: Height, 2: Full spectrum Albedo
	var pointsPerThread : int = floor(points.size() / (numThreads-1.0))
	Finished = 0
	for i in range(0,numThreads):
		thrd[i].start(_threadsSetTex.bind(i, role,img,pointsPerThread * i,min(pointsPerThread * (i+1),points.size())))
	while Finished != points.size():
		await get_tree().create_timer(2).timeout
	for i in range(0,numThreads):
		thrd[i].wait_to_finish()
		thrd[i] = Thread.new()
	for ClimateNode in points:
		MeshManipulator.set_vertex_color(ClimateNode.MeshIndex,ClimateNode.color)
	var commitmesh = ArrayMesh.new()
	MeshManipulator.commit_to_surface(commitmesh)
	planetMesh.mesh = commitmesh
	Finished = 0
	

func _threadsSetTex(_selfIndex : int, role : int, img : ImageTexture, lwrbound : int, uprbound : int):
	for i in range(lwrbound,uprbound):
		if(role == 0):
			points[i].color = img.get_image().get_pixelv(Vector2(fmod(1.0-(points[i].SphericalToLatLong(points[i].SphericalCoordinate).y / 360.0), 1.0), fmod(points[i].SphericalToLatLong(points[i].SphericalCoordinate).x / 180,1.0)) * img.get_size())
		elif (role == 1):
			var point = img.get_image().get_pixelv(Vector2(fmod(1.0-(points[i].SphericalToLatLong(points[i].SphericalCoordinate).y / 360.0), 1.0), fmod(points[i].SphericalToLatLong(points[i].SphericalCoordinate).x / 180,1.0)) * img.get_size())
			points[i].height = ((maxheight-minHeight) * point.r) + minHeight
		mut.lock()
		Finished += 1
		mut.unlock()

func reColor(layrs : Array[ButtonHost.layers]) -> void:
	var Cmin : Array[float] = [INF,INF,INF]
	var Cmax : Array[float] = [-INF,-INF,-INF]
	var Clrs : Array[Color] = []
	for i in range(0,points.size()):
		Clrs.append(Color.BLACK)
		var channel : int = 0
		for layer in layrs:
			if layer == ButtonHost.layers.TRUE:
				if(channel == 0):
					Clrs[i].r = points[i].color.r
				if(channel == 1):
					Clrs[i].g = points[i].color.g
				if(channel == 2):
					Clrs[i].b = points[i].color.b
			elif layer ==  ButtonHost.layers.HEIGHT:
				if(channel == 0):
					Clrs[i].r = (points[i].height - minHeight) / (maxheight - minHeight)
				if(channel == 1):
					Clrs[i].g = (points[i].height - minHeight) / (maxheight - minHeight)
				if(channel == 2):
					Clrs[i].b = (points[i].height - minHeight) / (maxheight - minHeight)
			elif layer == ButtonHost.layers.LATITUDE:
				if(channel == 0):
					Clrs[i].r = absf((2 * points[i].SphericalCoordinate.x) - PI) / PI
				if(channel == 1):
					Clrs[i].g = absf((2 * points[i].SphericalCoordinate.x) - PI) / PI
				if(channel == 2):
					Clrs[i].b = absf((2 * points[i].SphericalCoordinate.x) - PI) / PI
			elif layer == ButtonHost.layers.ENERGY:
				if(points[i].sumEnergy() < Cmin[channel]):
					Cmin[channel] = points[i].sumEnergy()
				if(points[i].sumEnergy() > Cmax[channel]):
					Cmax[channel] = points[i].sumEnergy()
			channel += 1
	for i in range(0,points.size()):
		var channel : int = 0
		for layer in layrs:
			if layer ==  ButtonHost.layers.ENERGY:
				if(channel == 0):
					Clrs[i].r = (points[i].sumEnergy() - Cmin[channel]) / (Cmax[channel] - Cmin[channel])
				if(channel == 1):
					Clrs[i].g = (points[i].sumEnergy() - Cmin[channel]) / (Cmax[channel] - Cmin[channel])
				if(channel == 2):
					Clrs[i].b = (points[i].sumEnergy() - Cmin[channel]) / (Cmax[channel] - Cmin[channel])
			channel += 1
		MeshManipulator.set_vertex_color(points[i].MeshIndex,Clrs[i])
	var commitmesh = ArrayMesh.new()
	MeshManipulator.commit_to_surface(commitmesh)
	planetMesh.mesh = commitmesh

func _exit_tree() -> void:
	for i in range(0,numThreads):
		thrd[i].wait_to_finish()
