extends Node

static var StefanBoltzmanConstant: float = 5.67037e-8 #W/M^2K^4
static var SunDiameter := 6.957e8
static var AUdefiniton := 149597870700
static var SolarConstant := 1370 #Wm^2

static var gases : Array[Dictionary] = [ #Needs sources
	#EARTH
	{"Name": "Nitrogen", "Weight":0}, 
	{"Name": "Atmoic Oxogen", "Weight":0},
	{"Name": "Molecular Oxygen", "Weight":0},
	{"Name": "Helium", "Weight":0},
	{"Name": "Argon", "Weight":0},
	{"Name": "Atomic Hydrogen", "Weight":0},
	{"Name": "Neon", "Weight":0},
	{"Name": "Krypton", "Weight":0},
	{"Name": "Xenon", "Weight":0},
	{"Name": "Nitrous Oxide", "Weight":0},
	{"Name": "Nitric Oxide", "Weight":0},
	{"Name": "Nitrogen Dioxide", "Weight":0},
	{"Name": "Hydrogen Sulfide", "Weight":0},
	{"Name": "Ammonia", "Weight":0},
	{"Name": "Molecular Hydrogen", "Weight":0},
	{"Name": "Methane", "Weight":0},
	{"Name": "Sulfur Dioxide", "Weight":0},
	{"Name": "Carbon Monoxide", "Weight":0},
	{"Name": "Carbon Dioxide", "Weight":0},
	{"Name": "Ozone", "Weight":0},
	
	#MARS
	
	#VENUS
	
	#TITAN
	
]
