class_name UI_control
extends Node

@export_category("Assignment")
@export var Menu : Control
@export var Tabs : TabBar
@export var TechMenu : Control
@export var LayersMenu : Control
@export var StarMenu : Control
@export var PlanetMenu : Control
@export var Uploader : Control
@export var boss : Worldbase

var prevMenu : int = -1

var ProjectDir : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Control Bar/Menu_Location/Technical/Body/Subdivisions/DetailBar".max_value = boss.World.TechnicalAspects.Subdivisions.size()-1
	$"Control Bar/Menu_Location/Technical/Body/Subdivisions/DetailBar".value = boss.World.subdivLevel
	$"Control Bar/Menu_Location/Star/Body/StarMass/SMass".text = str(boss.starMass)
	$"Control Bar/Menu_Location/Star/Body/StarLuminosity/SLuminosity".text = str(boss.starLuminosity)
	$"Control Bar/Menu_Location/Star/Body/StarTemperature/STemperature".text = str(boss.starTemp)
	$"Control Bar/Menu_Location/Star/Body/StarBolometricCorrection/SBolometric".text = str(boss.BolometricCorrectionStrength)
	
	$"Control Bar/Menu_Location/Planet/Body/RotationSpeed/PDayLength".text = str(boss.World.DaysSpeed*24)
	$"Control Bar/Menu_Location/Planet/Body/Distance/PDistance".text = str(boss.World.distance)
	$"Control Bar/Menu_Location/Planet/Body/YearLength/PYearLength".text = str(boss.World.YearLength)
	$"Control Bar/Menu_Location/Planet/Body/Tilt/PTilt".text = str(boss.World.tilt)
	$"Control Bar/Menu_Location/Planet/Body/Planet Radius/PRadius".text = str(boss.World.PlanetMass)
	$"Control Bar/Menu_Location/Planet/Body/Planet Mass/PMass".text = str(boss.World.PlanetRadius)
	
	$"Control Bar/Menu_Location/Technical/Body/X_Sensitivity/XSens".text = str(boss.Sensitivity.x * 100)
	$"Control Bar/Menu_Location/Technical/Body/Y_Sensitivity/YSens".text = str(boss.Sensitivity.y * 100)
	$"Control Bar/Menu_Location/Technical/Body/CameraDistance/CamDist".text = str(boss.CamDistance)
	$"Control Bar/Menu_Location/Technical/Body/Filepath/LineEdit".text = str(ProjectDir)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#switch view
	if prevMenu != Tabs.current_tab:
		print("Switching Tab! Set Tab:" + str(Tabs.current_tab) + ", Old Tab:" + str(prevMenu))
		if Tabs.current_tab == 0:
			TechMenu.visible = true
			LayersMenu.visible = false
			StarMenu.visible = false
			PlanetMenu.visible = false
			var scrl : VScrollBar = TechMenu.get_child(0)
			var furthest_child : Control = TechMenu.get_child(1).get_child(-1)
			scrl.max_value = 1/furthest_child.anchor_bottom
			scrl.value = 0
		if Tabs.current_tab == 1:
			TechMenu.visible = false
			LayersMenu.visible = true
			StarMenu.visible = false
			PlanetMenu.visible = false
			var scrl : VScrollBar = LayersMenu.get_child(0)
			var furthest_child : Control = LayersMenu.get_child(1).get_child(-1)
			scrl.max_value = 1/furthest_child.anchor_bottom
			scrl.value = 0
		if Tabs.current_tab == 2:
			TechMenu.visible = false
			LayersMenu.visible = false
			StarMenu.visible = true
			PlanetMenu.visible = false
			var scrl : VScrollBar = StarMenu.get_child(0)
			var furthest_child : Control = StarMenu.get_child(1).get_child(-1)
			scrl.max_value = 1/furthest_child.anchor_bottom
			scrl.value = 0
		if Tabs.current_tab == 3:
			TechMenu.visible = false
			LayersMenu.visible = false
			StarMenu.visible = false
			PlanetMenu.visible = true
			var scrl : VScrollBar = PlanetMenu.get_child(0)
			var furthest_child : Control = PlanetMenu.get_child(1).get_child(-1)
			scrl.max_value = 1/furthest_child.anchor_bottom
			scrl.value = 0
		prevMenu = Tabs.current_tab
	#assignments
	boss.World.subdivLevel = $"Control Bar/Menu_Location/Technical/Body/Subdivisions/DetailBar".value
	boss.starMass = $"Control Bar/Menu_Location/Star/Body/StarMass/SMass".text
	boss.starLuminosity = $"Control Bar/Menu_Location/Star/Body/StarLuminosity/SLuminosity".text
	boss.starTemp = $"Control Bar/Menu_Location/Star/Body/StarTemperature/STemperature".text
	boss.BolometricCorrectionStrength = $"Control Bar/Menu_Location/Star/Body/StarBolometricCorrection/SBolometric".text
	boss.World.DaysSpeed = float($"Control Bar/Menu_Location/Planet/Body/RotationSpeed/PDayLength".text) / 24
	boss.World.distance = $"Control Bar/Menu_Location/Planet/Body/Distance/PDistance".text
	boss.World.YearLength = $"Control Bar/Menu_Location/Planet/Body/YearLength/PYearLength".text
	boss.World.tilt = $"Control Bar/Menu_Location/Planet/Body/Tilt/PTilt".text
	boss.World.PlanetMass = $"Control Bar/Menu_Location/Planet/Body/Planet Mass/PMass".text
	boss.World.PlanetRadius = $"Control Bar/Menu_Location/Planet/Body/Planet Radius/PRadius".text
	boss.World.PlanetName = $"Control Bar/Menu_Location/Planet/Body/PlanetName/PName".text
	boss.Sensitivity = Vector2(float($"Control Bar/Menu_Location/Technical/Body/X_Sensitivity/XSens".text),float($"Control Bar/Menu_Location/Technical/Body/Y_Sensitivity/YSens".text)) / 100.0
	ProjectDir = $"Control Bar/Menu_Location/Technical/Body/Filepath/LineEdit".text
	
	if(float($"Control Bar/Menu_Location/Technical/Body/CameraDistance/CamDist".text) != boss.CamDistance):
		boss.CamDistance = $"Control Bar/Menu_Location/Technical/Body/CameraDistance/CamDist".text
		boss.UpdateCam()
	
	$"Control Bar/Menu_Location/Planet/Body/UploadLayers/ProgressBar".value = boss.World.Finished
	$"Control Bar/Menu_Location/Planet/Body/UploadLayers/ProgressBar".max_value = boss.World.points.size()
	var t_size = $"Control Bar/Menu_Location/Technical/Body".get_size().y
	var l_size = $"Control Bar/Menu_Location/Layers/Body".get_size().y
	var s_size = $"Control Bar/Menu_Location/Star/Body".get_size().y
	var p_size = $"Control Bar/Menu_Location/Planet/Body".get_size().y
	$"Control Bar/Menu_Location/Technical/Body".offset_bottom = ($"Control Bar/Menu_Location/Technical/T_Scroll".value) * -t_size
	$"Control Bar/Menu_Location/Layers/Body".offset_bottom = ($"Control Bar/Menu_Location/Layers/L_Scroll".value) * -l_size
	$"Control Bar/Menu_Location/Star/Body".offset_bottom = ($"Control Bar/Menu_Location/Star/S_Scroll".value) * -s_size
	$"Control Bar/Menu_Location/Planet/Body".offset_bottom = ($"Control Bar/Menu_Location/Planet/P_Scroll".value) * -p_size
	$"Control Bar/Menu_Location/Technical/Body".offset_top = ($"Control Bar/Menu_Location/Technical/T_Scroll".value) * -t_size
	$"Control Bar/Menu_Location/Layers/Body".offset_top = ($"Control Bar/Menu_Location/Layers/L_Scroll".value) * -l_size
	$"Control Bar/Menu_Location/Star/Body".offset_top = ($"Control Bar/Menu_Location/Star/S_Scroll".value) * -s_size
	$"Control Bar/Menu_Location/Planet/Body".offset_top = ($"Control Bar/Menu_Location/Planet/P_Scroll".value) * -p_size
	
func mCameraL():
	boss.MoveCamera(true)

func mCameraR():
	boss.MoveCamera(false)

func sCamera():
	boss.StopCamera()

func loadDir():
	var fileCrawler = DirAccess.open(ProjectDir)
	fileCrawler.list_dir_begin()
	var file_name = fileCrawler.get_next()
	var directories : Array[String] = []
	while file_name != "":
		if fileCrawler.current_is_dir():
			print("Directory: ", file_name)
			directories.append(String(file_name))
		file_name = fileCrawler.get_next()
	print(directories)
	var isfirst = true
	for dir in directories:
		print(dir)
		if isfirst:
			fileCrawler.change_dir(dir)
		else:
			fileCrawler.change_dir("../" + dir)
		fileCrawler.list_dir_begin()
		var file = fileCrawler.get_next()
		while file != "":
			if fileCrawler.current_is_dir():
				print("SubDirectories! ",file)
			else:
				print("Found a file! ", file)
				var fileReader = FileAccess.open(fileCrawler.get_current_dir() + "/" + file,FileAccess.READ)
				var JSON_reader = fileReader.get_line()
				fileReader.close()
				var json = JSON.new()
				var er = json.parse(JSON_reader)
				if er:
					print("JSON could not be read: ", er, " (",fileCrawler.get_current_dir() + "/" + file,")")
					return
				var data = json.data
				if(data["Type"] == "Planet"):
					boss.World.PlanetName = data["PlanetData"]["PlanetName"]
					boss.World.DaysSpeed = data["PlanetData"]["Scientific"]["DaySpeed"]
					boss.World.distance = data["PlanetData"]["Scientific"]["Distance"]
					boss.World.tilt = data["PlanetData"]["Scientific"]["Tilt"]
					boss.World.YearLength = data["PlanetData"]["Scientific"]["YearLength"]
					boss.World.PlanetMass = data["PlanetData"]["Scientific"]["Mass"]
					boss.World.PlanetRadius = data["PlanetData"]["Scientific"]["Radius"]
					boss.World.forceMesh(data["PlanetData"]["SubdivLevel"])
					$"Control Bar/Menu_Location/Planet/Body/PlanetName/PName".text = boss.World.PlanetName
					$"Control Bar/Menu_Location/Planet/Body/RotationSpeed/PDayLength".text = str(boss.World.DaysSpeed*24)
					$"Control Bar/Menu_Location/Planet/Body/Distance/PDistance".text = str(boss.World.distance)
					$"Control Bar/Menu_Location/Planet/Body/YearLength/PYearLength".text = str(boss.World.YearLength)
					$"Control Bar/Menu_Location/Planet/Body/Tilt/PTilt".text = str(boss.World.tilt)
					$"Control Bar/Menu_Location/Planet/Body/Planet Radius/PRadius".text = str(boss.World.PlanetMass)
					$"Control Bar/Menu_Location/Planet/Body/Planet Mass/PMass".text = str(boss.World.PlanetRadius)
					$"Control Bar/Menu_Location/Technical/Body/Subdivisions/DetailBar".value = boss.World.subdivLevel
				elif(data["Type"] == "ClimateModel"):
					boss.World.points.clear()
					for point in data["Model Data"]:
						var p = PlanetDataPoint.new(point["Index"],Vector3.UP,Color(point["color"]["r"],point["color"]["g"],point["color"]["b"]))
						p.SphericalCoordinate = Vector2(point["Coordinates"]["x"],point["Coordinates"]["y"])
						p.height = point["Height"]
						boss.World.points.append(p)
					boss.World.force_colors()
				elif(data["Type"] == "Star"):
					boss.StarName = data["StarData"]["StarName"]
					boss.starMass = data["StarData"]["Mass"]
					boss.starLuminosity = data["StarData"]["Luminosity"]
					boss.starTemp = data["StarData"]["Temperature"]
					boss.BolometricCorrectionStrength = data["StarData"]["BolometricCorrectionStrength"]
					$"Control Bar/Menu_Location/Star/Body/StarName/SName".text = boss.StarName
					$"Control Bar/Menu_Location/Star/Body/StarMass/SMass".text = str(boss.starMass)
					$"Control Bar/Menu_Location/Star/Body/StarLuminosity/SLuminosity".text = str(boss.starLuminosity)
					$"Control Bar/Menu_Location/Star/Body/StarTemperature/STemperature".text = str(boss.starTemp)
					$"Control Bar/Menu_Location/Star/Body/StarBolometricCorrection/SBolometric".text = str(boss.BolometricCorrectionStrength)
				elif(data["Type"] == "Technical"):
					boss.Sensitivity.x = data["TechnicalData"]["XSensitivity"]
					boss.Sensitivity.y = data["TechnicalData"]["YSensitivity"]
					boss.CamDistance = data["TechnicalData"]["CameraDistance"]
					boss.sM = data["TechnicalData"]["StarMap"]
					boss.nM = data["TechnicalData"]["NebulaMap"]
					$"Control Bar/Menu_Location/Technical/Body/X_Sensitivity/XSens".text = str(boss.Sensitivity.x * 100)
					$"Control Bar/Menu_Location/Technical/Body/Y_Sensitivity/YSens".text = str(boss.Sensitivity.y * 100)
					$"Control Bar/Menu_Location/Technical/Body/CameraDistance/CamDist".text = str(boss.CamDistance)
				else:
					print("Invalid!")
			file = fileCrawler.get_next()
		isfirst = false
		

func saveDir():
	var PlanetPoints = []
	for p in boss.World.points:
		PlanetPoints.append({
			"Index" = p.MeshIndex,
			"Coordinates" = {"x" = p.SphericalCoordinate.x, "y" = p.SphericalCoordinate.y},
			"Height" = p.height,
			"color" = {"r" = p.color.r, "g" = p.color.g, "b" = p.color.b}
		})
	var SName = boss.StarName.replace(" ","_")
	var PName = boss.World.PlanetName.replace(" ","_")
	var PointData := {
		"Type" = "ClimateModel",
		"Planet" = PName,
		"Model Data" = PlanetPoints,
	}
	var PlanetData := {
		"Type" = "Planet",
		"PlanetData" = {
			"PlanetName" = boss.World.PlanetName,
			"Scientific" = {
				"DaySpeed" = boss.World.DaysSpeed,
				"Distance" = boss.World.distance,
				"Tilt" = boss.World.tilt,
				"YearLength" = boss.World.YearLength,
				"Mass" = boss.World.PlanetMass,
				"Radius" = boss.World.PlanetRadius,
			},
			"SubdivLevel" = boss.World.subdivLevel,
		}
	}
	var StarData = {
		"Type" = "Star",
		"StarData" = {
			"StarName" = boss.StarName,
			"Mass" = boss.starMass,
			"Luminosity" = boss.starLuminosity,
			"Temperature" = boss.starTemp,
			"BolometricCorrectionStrength" = boss.BolometricCorrectionStrength,
		}
	}
	var TechnicalData = {
		"Type" = "Technical",
		"TechnicalData" = {
			"XSensitivity" = boss.Sensitivity.x,
			"YSensitivity" = boss.Sensitivity.y,
			"CameraDistance" = boss.CamDistance,
			"StarMap" = boss.sM,
			"NebulaMap" = boss.nM,
		}
	}
	
	var fileCrawler = DirAccess.open(ProjectDir)
	if(!fileCrawler.dir_exists("Stars")):
		fileCrawler.make_dir("Stars")
	fileCrawler.change_dir("Stars")
	var StarFile = FileAccess.open(fileCrawler.get_current_dir() + "/" + SName + ".json",FileAccess.WRITE)
	if not StarFile:
		print("StarFile failed: ", FileAccess.get_open_error())
		return
	
	StarFile.store_line(JSON.stringify(StarData))
	StarFile.close()
	
	if(!fileCrawler.dir_exists("../"+PName)):
		fileCrawler.make_dir("../"+PName)
	fileCrawler.change_dir("../"+PName)
	var PlanetFile = FileAccess.open(fileCrawler.get_current_dir() + "/" + PName + ".json",FileAccess.WRITE)
	if not PlanetFile:
		print("PlanetFile failed: ", FileAccess.get_open_error())
		return
	
	PlanetFile.store_line(JSON.stringify(PlanetData))
	PlanetFile.close()
	
	var PlanetModelFile = FileAccess.open(fileCrawler.get_current_dir() + "/" + PName + "__climate.json",FileAccess.WRITE)
	if not PlanetModelFile:
		print("PlanetModelFile failed: ", FileAccess.get_open_error())
		return
	
	PlanetModelFile.store_line(JSON.stringify(PointData))
	PlanetModelFile.close()
	
	if(!fileCrawler.dir_exists("../Technical")):
		fileCrawler.make_dir("../Technical")
	fileCrawler.change_dir("../Technical")
	var TechFile = FileAccess.open(fileCrawler.get_current_dir() + "/Technical.json",FileAccess.WRITE)
	if not TechFile:
		print("TechFile failed: ", FileAccess.get_open_error())
		return
	
	TechFile.store_line(JSON.stringify(TechnicalData))
	TechFile.close()

func passImg(role: int, img: ImageTexture): #0: Color, 1: Height, 2: Full spectrum Albedo
	boss.World.SetTex(role,img)

func passColor():
	passImg(0,Uploader.get_child(3).texture)

func passHeight():
	passImg(1,Uploader.get_child(3).texture)


func StarNamed(new_text: String) -> void:
	boss.StarName = new_text
	if(boss.World.PlanetName == ""):
		boss.World.PlanetName = new_text + " b"
		$"Control Bar/Menu_Location/Planet/Body/PlanetName/PName".text = new_text + " b"
