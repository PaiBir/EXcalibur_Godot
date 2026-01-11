class_name UI_control
extends Node

@export_category("Assignment")
@export var Menu : Control
@export var Tabs : TabBar
@export var TechMenu : Control
@export var LayersMenu : Control
@export var StarMenu : Control
@export var PlanetMenu : Control
@export var boss : Worldbase

var prevMenu : int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Control Bar/Menu_Location/Technical/Body/Subdivisions/DetailBar".max_value = boss.World.TechnicalAspects.Subdivisions.size()-1
	$"Control Bar/Menu_Location/Technical/Body/Subdivisions/DetailBar".value = boss.World.subdivLevel
	$"Control Bar/Menu_Location/Star/Body/StarMass/SMass".text = str(boss.starMass)
	$"Control Bar/Menu_Location/Star/Body/StarLuminosity/SLuminosity".text = str(boss.starLuminosity)
	$"Control Bar/Menu_Location/Star/Body/StarTemperature/STemperature".text = str(boss.starTemp)
	$"Control Bar/Menu_Location/Planet/Body/RotationSpeed/PDayLength".text = str(boss.World.DaysSpeed*24)
	$"Control Bar/Menu_Location/Planet/Body/Distance/PDistance".text = str(boss.World.distance)
	$"Control Bar/Menu_Location/Planet/Body/YearLength/PYearLength".text = str(boss.World.YearLength)
	$"Control Bar/Menu_Location/Planet/Body/Tilt/PTilt".text = str(boss.World.tilt)
	$"Control Bar/Menu_Location/Technical/Body/X_Sensitivity/XSens".text = str(boss.Sensitivity.x * 100)
	$"Control Bar/Menu_Location/Technical/Body/Y_Sensitivity/YSens".text = str(boss.Sensitivity.y * 100)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#switch view
	if prevMenu != Tabs.current_tab:
		if Tabs.current_tab == 0:
			TechMenu.visible = true
			LayersMenu.visible = false
			StarMenu.visible = false
			PlanetMenu.visible = false
		if Tabs.current_tab == 1:
			TechMenu.visible = false
			LayersMenu.visible = true
			StarMenu.visible = false
			PlanetMenu.visible = false
		if Tabs.current_tab == 2:
			TechMenu.visible = false
			LayersMenu.visible = false
			StarMenu.visible = true
			PlanetMenu.visible = false
		if Tabs.current_tab == 3:
			TechMenu.visible = false
			LayersMenu.visible = false
			StarMenu.visible = false
			PlanetMenu.visible = true
	#assignments
	boss.World.subdivLevel = $"Control Bar/Menu_Location/Technical/Body/Subdivisions/DetailBar".value
	boss.starMass = $"Control Bar/Menu_Location/Star/Body/StarMass/SMass".text
	boss.starLuminosity = $"Control Bar/Menu_Location/Star/Body/StarLuminosity/SLuminosity".text
	boss.starTemp = $"Control Bar/Menu_Location/Star/Body/StarTemperature/STemperature".text
	boss.World.DaysSpeed = float($"Control Bar/Menu_Location/Planet/Body/RotationSpeed/PDayLength".text) / 24
	boss.World.distance = $"Control Bar/Menu_Location/Planet/Body/Distance/PDistance".text
	boss.World.YearLength = $"Control Bar/Menu_Location/Planet/Body/YearLength/PYearLength".text
	boss.World.tilt = $"Control Bar/Menu_Location/Planet/Body/Tilt/PTilt".text
	boss.Sensitivity = Vector2(float($"Control Bar/Menu_Location/Technical/Body/X_Sensitivity/XSens".text),float($"Control Bar/Menu_Location/Technical/Body/Y_Sensitivity/YSens".text)) / 100.0
	
func mCameraL():
	boss.MoveCamera(true)

func mCameraR():
	boss.MoveCamera(false)

func sCamera():
	boss.StopCamera()

func loadDir():
	pass

func saveDir():
	pass
