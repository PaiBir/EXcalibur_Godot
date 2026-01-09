class_name Worldbase
extends Node3D

@export_category("Star Properties")
@export_subgroup("Bolometric")
@export var BolometricCorrectionBezier : Array[Bezier]
@export var BolometricCorrectionStrength : float

@export_subgroup("Physical Characteristics")
@export_range(0.01,20,0.01,"suffix:M☉") var starMass : float = 1.0
@export_range(0.01,100000,0.01,"suffix:L☉") var starLuminosity : float = 1.0
@export_range(1000,150000,1,"suffix:K") var starTemp : float = 5776
var starDiameter : float;
var starAbsMagnitude : float;

@export_category("Technical")
@export var Skybox : Material;
@export var UI_Base : Control;
@export var cam : Camera3D;
@onready var World : PlanetManager = $Manager
@export var RealLight : DirectionalLight3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	RealLight.light_energy = (starLuminosity/pow(World.distance,2))
	RealLight.light_color = TemperatureToColor(starTemp)
	var Bolometrics : float = 0
	for segment in BolometricCorrectionBezier:
		if starMass <= segment.xBound2 and starMass >= segment.xBound1:
			Bolometrics = segment.sampleCurve(starMass)
			break
	var bolometricLuminocity = starLuminosity / pow(2.52,Bolometrics*BolometricCorrectionStrength)
	starDiameter = 5776.0 / starTemp * sqrt(bolometricLuminocity)
	starAbsMagnitude = (log(bolometricLuminocity)/log(2.52)) + 4.85
	var starAngularDiameter = 2 * acos(sqrt(pow(World.distance * Constants.AUdefiniton, 2) - pow(starDiameter * Constants.SunDiameter, 2)) / (World.distance * Constants.AUdefiniton))

#Based on Mitchell Charity's function as reported by Dan Bruton (https://web.archive.org/web/20241106151814/https://www.physics.sfasu.edu/astro/color/blackbody.html)
func TemperatureToColor(temp : float) -> Color:
	var reColor : Color = Color(
		max(min((56100000.0 * pow(temp,-3.0/2.0) + 148.0) / 255.0, 1), 0),
		max(min((100.04 * log(temp) - 623.6) / 255.0, 1), 0),
		max(min((194.18 * log(temp) - 1448.6) / 255.0, 1), 0),
		1)
	
	if temp > 6500:
		reColor.g = max(min((35200000.0 * pow(temp,-3.0/2.0) + 148.0) / 255.0, 1), 0)
	
	return(reColor)
