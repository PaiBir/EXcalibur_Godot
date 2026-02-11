class_name MODELTIMER
extends Node

@export var Output : OUTPUTTER
@export var Controller : CLIMBER_X_CONTROL

var StepOfYear : int = 0
var DayOfYear : int = 0
var Month : int = 0
var Year_True : int = 0
var Year_Geo : int = 0
var Year_Climate : int = 0
var Year_SMB : int = 0
var Number_Of_Years : int = 0
var Number_Of_Years_Climate : int = 0
var Number_Of_Years_Geo : int = 0
var Initial_Year : int = 0
var Current_Year : int = 0
var Step : int = 1
var NStep : int = 1
var NStep_Day : int = 1
var NStep_Month : int = 1
var NStep_Year : int = 1
var Step_Atmosphere : int = 1
var Step_Land : int = 1
var Step_Ocean : int = 1
var Step_Sea_Ice : int = 1
var Step_BGC : int = 1
var Step_SMB : int = 1
var Step_BMB : int = 1
var Step_Ice : int = 1

#A different copy of this should be set in the UI. Then greater ffunctionality can be given
#Can't figure out leaps at the moment. Will attempt a solution later
var DaysPerYear : int = 365
var MonthsPerYear : int = 12
var DaysPerMonth : int = 30

var SecondsPerYear : float = 31556926 #No clue why this is the magic number of choice. Perhaps later replace with calculation based on rotation speed?
var SecondsPerYear_Inverse : float = 1 / SecondsPerYear
var SecondsPerDay : float = SecondsPerYear / DaysPerYear
var SecondsPerMonth : float = SecondsPerYear / MonthsPerYear
var Atmosphere_Timestep_Days : float = 1
var Land_Timestep_Days : float = 1
var SeaIce_Timestep_Days : float = 1
var IceSheet_Timestep_Days : float = 1
var Ocean_Timestep_Days : float = 1
var BGC_Timestep_Days : float = 1
var SMB_Timestep_Days : float = 1
var BMB_Timestep_Days : float = 1
var Fastest_Timestep_Days : float = 1

var Atmo_Timestep : float = 0
var Land_Timestep : float = 0
var Ocean_Timestep : float = 0
var BGC_Timestep : float = 0
var SeaIce_Timestep : float = 0
var SMB_Timestep : float = 0
var BMB_Timestep : float = 0
var Geo_Timestep : float = 0
var Fastest_Timestep : float = 0

var Ice_Years : int = 0
var SMB_Years : int = 0
var Geo_Years : int = 0
var Acceleration : int = 0

var NStep_Day_Atmosphere : int = 0
var NStep_Month_Atmosphere : int = 0
var NStep_Year_Atmosphere : int = 0
var NStep_Day_Ocean : int = 0
var NStep_Month_Ocean : int = 0
var NStep_Year_Ocean : int = 0
var NStep_Day_BGC : int = 0
var NStep_Month_BGC : int = 0
var NStep_Year_BGC : int = 0
var NStep_Day_SeaIce : int = 0
var NStep_Month_SeaIce : int = 0
var NStep_Year_SeaIce : int = 0
var NStep_Day_Land : int = 0
var NStep_Month_Land : int = 0
var NStep_Year_Land : int = 0
var NStep_Day_SMB : int = 0
var NStep_Month_SMB : int = 0
var NStep_Year_SMB : int = 0
var NStep_Day_BMB : int = 0
var NStep_Month_BMB : int = 0
var NStep_Year_BMB : int = 0

var Time_SOY : bool = false
var Time_EOY : bool = false
var Time_SOM : bool = false
var Time_EOM : bool = false
var Atmosphere_SOY : bool = false
var Atmosphere_EOY : bool = false
var Atmosphere_SOM : bool = false
var Atmosphere_EOM : bool = false
var Atmosphere_SOD : bool = false
var Atmosphere_EOD : bool = false
var Ocean_SOY : bool = false
var Ocean_EOY : bool = false
var Ocean_SOM : bool = false
var Ocean_EOM : bool = false
var Ocean_SOD : bool = false
var Ocean_EOD : bool = false
var BGC_SOY : bool = false
var BGC_EOY : bool = false
var BGC_SOM : bool = false
var BGC_EOM : bool = false
var BGC_SOD : bool = false
var BGC_EOD : bool = false
var SeaIce_SOY : bool = false
var SeaIce_EOY : bool = false
var SeaIce_SOM : bool = false
var SeaIce_EOM : bool = false
var SeaIce_SOD : bool = false
var SeaIce_EOD : bool = false
var Land_SOY : bool = false
var Land_EOY : bool = false
var Land_SOM : bool = false
var Land_EOM : bool = false
var Land_SOD : bool = false
var Land_EOD : bool = false
var SMB_SOY : bool = false
var SMB_EOY : bool = false
var SMB_SOM : bool = false
var SMB_EOM : bool = false
var SMB_SOD : bool = false
var SMB_EOD : bool = false
var BMB_SOY : bool = false
var BMB_EOY : bool = false
var BMB_SOM : bool = false
var BMB_EOM : bool = false
var BMB_SOD : bool = false
var BMB_EOD : bool = false
var BND_SOY : bool = false
var Feedback_Save : bool = false
var Feedback_Analysis : bool = false
var Spinup_CC_1 : bool = false
var Spinup_CC_2 : bool = false
var Call_Daily_Input_Save : bool = false
var Use_Daily_Input_Save : bool = false
var Write_Restart : bool = false

var Year_Out_Start : int = 0
var Year_Out_TS : int = 0
var Year_Out_TS_GEO : int = 0
var Year_Out_TS_CLIM : int = 0
var Year_Out_TS_SMB : int = 0
var NYear_Out_TS : int = 0
var NYear_Out_TS_GEO : int = 0
var NYear_Out_TS_Acceleration : int = 0
var NYear_Out_TS_SMB : int = 0
var NYear_Out_CMN : int = 0
var NYear_Out_Atmosphere : int = 0
var NYear_Out_Land : int = 0
var NYear_Out_Ocean : int = 0
var NYear_Out_SeaIce : int = 0
var NYear_Out_BGC : int = 0
var NYear_Out_SMB : int = 0
var NYear_Out_BMB : int = 0
var NYear_Out_Ice : int = 0
var NYear_Out_Geo : int = 0

var Time_Out_TS : bool = false
var Time_Out_TS_Geo : bool = false
var Time_Out_TS_Clim : bool = false
var Time_Out_TS_SMB : bool = false
var Time_Out_CMN : bool = false
var Time_Out_Atmosphere : bool = false
var Time_Out_Land : bool = false
var Time_Out_Ocean : bool = false
var Time_Out_SeaIce : bool = false
var Time_Out_BGC : bool = false
var Time_Out_SMB : bool = false
var Time_Out_BMB : bool = false
var Time_Out_Ice : bool = false
var Time_Out_Geo : bool = false

var Time_Call_Atmosphere : bool = false
var Time_Call_Land : bool = false
var Time_Call_Ocean : bool = false
var Time_Call_SeaIce : bool = false
var Time_Call_BGC : bool = false
var Time_Call_SMB : bool = false
var Time_Call_BMB : bool = false
var Time_Call_Ice : bool = false
var Time_Call_Geo : bool = false
var Time_Call_Clim : bool = false

func timer_init(fromFile : bool = false):
	pass
	if(fromFile):
		var TimerParams = FileAccess.open(Output.OutputDirectory + "/CLIMBER_Model/General/Timer.json",FileAccess.READ)
		var JSONlines = TimerParams.get_line()
		TimerParams.close()
		var JSONER = JSON.new()
		JSONER.parse(JSONlines)
		timer_param_load(JSONER.data)
	
	NStep_Year_SMB = max(NStep_Year_SMB,Acceleration)
	##CLIMBER-X can't handle a NStep_Year_SMB that isn't a multiple of Acceleration. Possible diagnosis is in play, but maintaining this code as comment in case it isn't
	#if(fmod(NStep_Year_SMB,Acceleration)!=0):
	#	printerr("timer_init(): Initialiation failure, NStep_Year_SMB is not a multiple of Acceleration (%d, %d)" % [NStep_Year_SMB, Acceleration])
	#	return
	
	IceSheet_Timestep_Days = Ice_Years * DaysPerYear
	Fastest_Timestep_Days = INF
	if (Controller.FLAG_ATMOSPHERE):
		Fastest_Timestep_Days = min(Fastest_Timestep_Days,Atmosphere_Timestep_Days)
	if (Controller.FLAG_LAND):
		Fastest_Timestep_Days = min(Fastest_Timestep_Days,Land_Timestep_Days)
	if (Controller.FLAG_OCEAN):
		Fastest_Timestep_Days = min(Fastest_Timestep_Days,Ocean_Timestep_Days)
	if (Controller.FLAG_BGC):
		Fastest_Timestep_Days = min(Fastest_Timestep_Days,BGC_Timestep_Days)
	if (Controller.FLAG_SEAICE):
		Fastest_Timestep_Days = min(Fastest_Timestep_Days,SeaIce_Timestep_Days)
	if (Controller.FLAG_SMB):
		Fastest_Timestep_Days = min(Fastest_Timestep_Days,SMB_Timestep_Days)
	if (Controller.FLAG_BMB):
		Fastest_Timestep_Days = min(Fastest_Timestep_Days,BMB_Timestep_Days)
	if (Controller.FLAG_ICESHEET):
		Fastest_Timestep_Days = min(Fastest_Timestep_Days,IceSheet_Timestep_Days)
	if (Controller.FLAG_GEO):
		Fastest_Timestep_Days = min(Fastest_Timestep_Days,Atmosphere_Timestep_Days)
	print(Fastest_Timestep_Days)
	
	#Determine the numbr of timesteps to process
	Number_Of_Years_Climate = ceil(float(Number_Of_Years) / Acceleration) * Acceleration #bumps the number of climate timesteps to process to only have full timesteps
	Number_Of_Years_Geo = ceil(float(Number_Of_Years) / Number_Of_Years_Geo) * Number_Of_Years_Geo #same as with Number_Of_Years_Climate
	if (Controller.FLAG_GEO):
		Number_Of_Years = max(Number_Of_Years_Climate,Number_Of_Years_Geo) #determine the number of timesteps neded
	else:
		Number_Of_Years = Number_Of_Years_Climate #This isn't in Climber-X, but I think that might solve their earlier issue
	
	print("The number of years to process is: ", Number_Of_Years)
	NStep = int(Number_Of_Years * DaysPerYear / float(Fastest_Timestep_Days))
	NYear_Out_TS = min(100,Number_Of_Years) #How often the output is saved
	NStep_Day = int(1.0/float(Fastest_Timestep_Days))
	NStep_Month = int(DaysPerMonth/float(Fastest_Timestep_Days))
	NStep_Year = int(DaysPerYear/float(Fastest_Timestep_Days))
	NYear_Out_TS_Acceleration = NYear_Out_TS * Acceleration
	NYear_Out_TS_SMB = NYear_Out_TS * SMB_Years
	NYear_Out_TS_SMB = NYear_Out_TS * Geo_Years
	
	#Getting nice interger values for model timesteps
	Step_Atmosphere = int(Atmosphere_Timestep_Days / Fastest_Timestep_Days)
	Step_Land = int(Land_Timestep_Days / Fastest_Timestep_Days)
	Step_Ocean = int(Ocean_Timestep_Days / Fastest_Timestep_Days)
	Step_BGC = int(BGC_Timestep_Days / Fastest_Timestep_Days)
	Step_Sea_Ice = int(SeaIce_Timestep_Days / Fastest_Timestep_Days)
	Step_SMB = int(SMB_Timestep_Days / Fastest_Timestep_Days)
	Step_BMB = int(BMB_Timestep_Days / Fastest_Timestep_Days)
	Step_Ice = int(IceSheet_Timestep_Days / Fastest_Timestep_Days)
	
	NStep_Day_Atmosphere = max(1,int(1.0/Atmosphere_Timestep_Days))
	NStep_Day_Land = max(1,int(1.0/Land_Timestep_Days))
	NStep_Day_Ocean = max(1,int(1.0/Ocean_Timestep_Days))
	NStep_Day_BGC = max(1,int(1.0/BGC_Timestep_Days))
	NStep_Day_SeaIce = max(1,int(1.0/SeaIce_Timestep_Days))
	NStep_Day_SMB = max(1,int(1.0/SMB_Timestep_Days))
	NStep_Day_BMB = max(1,int(1.0/BMB_Timestep_Days))
	
	NStep_Month_Atmosphere = max(1,int(DaysPerMonth/Atmosphere_Timestep_Days))
	NStep_Month_Land = max(1,int(DaysPerMonth/Land_Timestep_Days))
	NStep_Month_Ocean = max(1,int(DaysPerMonth/Ocean_Timestep_Days))
	NStep_Month_BGC = max(1,int(DaysPerMonth/BGC_Timestep_Days))
	NStep_Month_SeaIce = max(1,int(DaysPerMonth/SeaIce_Timestep_Days))
	NStep_Month_SMB = max(1,int(DaysPerMonth/SMB_Timestep_Days))
	NStep_Month_BMB = max(1,int(DaysPerMonth/BMB_Timestep_Days))
	
	NStep_Year_Atmosphere = max(1,int(DaysPerYear/Atmosphere_Timestep_Days))
	NStep_Year_Land = max(1,int(DaysPerYear/Land_Timestep_Days))
	NStep_Year_Ocean = max(1,int(DaysPerYear/Ocean_Timestep_Days))
	NStep_Year_BGC = max(1,int(DaysPerYear/BGC_Timestep_Days))
	NStep_Year_SeaIce = max(1,int(DaysPerYear/SeaIce_Timestep_Days))
	NStep_Year_SMB = max(1,int(DaysPerYear/SMB_Timestep_Days))
	NStep_Year_BMB = max(1,int(DaysPerYear/BMB_Timestep_Days))
	
	Atmo_Timestep = Atmosphere_Timestep_Days * SecondsPerDay
	Land_Timestep = Land_Timestep_Days * SecondsPerDay
	Ocean_Timestep = Ocean_Timestep_Days * SecondsPerDay
	BGC_Timestep = BGC_Timestep_Days * SecondsPerDay
	SeaIce_Timestep = SeaIce_Timestep_Days * SecondsPerDay
	Land_Timestep = Land_Timestep_Days * SecondsPerDay
	SMB_Timestep = SMB_Timestep_Days * SecondsPerDay
	BMB_Timestep = BMB_Timestep_Days * SecondsPerDay
	Geo_Timestep = Geo_Years * SecondsPerYear
	
	DayOfYear = 0
	Month = 0
	Year_True = 0
	
	print("\nTimer_Initiation:\nAcceleration:%s\nAtmosphere_Step:%s,Land_Step:%s,Ocean_Step:%s,SeaIce_Step:%s,BGC_Step:%s,SMB_Step:%s,BMB_Step:%s,IceSheet_Step:%s\n" % [Acceleration,Step_Atmosphere,Step_Land,Step_Ocean,Step_Sea_Ice,Step_BGC,Step_SMB,Step_BMB,Step_Ice])

func timer_param_load(data):
	Number_Of_Years = data["Number_Of_Years"]
	Initial_Year = data["Initial_Year"]
	Ocean_Timestep_Days = data["Ocean_Timestep_Days"]
	BGC_Timestep_Days = data["Timestep_Days"]["BGC"]
	SMB_Timestep_Days = data["Timestep_Days"]["SMB"]
	BMB_Timestep_Days = data["Timestep_Days"]["BMB"]
	Ice_Years = data["Years_Ice"]
	SMB_Years = data["Years_SMB"]
	Geo_Years = data["Years_Geo"]
	Year_Out_Start = data["Year_Out_Start"]
	NYear_Out_CMN = data["NYear_Out"]["CMN"]
	NYear_Out_Atmosphere = data["NYear_Out"]["Atmosphere"]
	NYear_Out_Land = data["NYear_Out"]["Land"]
	NYear_Out_Ocean = data["NYear_Out"]["Ocean"]
	NYear_Out_BGC = data["NYear_Out"]["BGC"]
	NYear_Out_SeaIce = data["NYear_Out"]["SeaIce"]
	NYear_Out_SMB = data["NYear_Out"]["SMB"]
	NYear_Out_BMB = data["NYear_Out"]["BMB"]
	NYear_Out_Ice = data["NYear_Out"]["Ice"]
	NYear_Out_Geo = data["NYear_Out"]["Geo"]
	Acceleration = data["Acceleration"]

func timer_update():
	var time_now : int = int(Step * Fastest_Timestep) #time in seconds
	StepOfYear = int(fmod(Step,NStep_Year))
	if(StepOfYear == 0):
		StepOfYear = NStep_Year
	DayOfYear = int(fmod(floor((time_now - 0.01) / SecondsPerDay)+1,DaysPerYear))
	if(DayOfYear == 0):
		DayOfYear = DaysPerYear
	Month = int((DayOfYear - 1) / float(DaysPerMonth) + 1)
	Year_True = floor((time_now - 0.5 * Fastest_Timestep) / SecondsPerYear) + 1
	
	Year_Climate = ceili(Year_True / float(Acceleration))
	Year_SMB = ceili(Year_True / float(SMB_Years))
	Year_Geo = ceili(Year_True / float(Geo_Years))
	
	Current_Year = Initial_Year+Year_True
	
	print("%s, Current Time: %s\n%s : %s : %s (%s)\n" % [Step,time_now,Year_True,Month,DayOfYear,StepOfYear] + str((time_now - 1) / SecondsPerDay) + ", " + str(floor((time_now - 1) / SecondsPerDay) + 1), ", " + str(int(time_now / SecondsPerDay)) + "\n" + str((time_now - 0.5 * Fastest_Timestep) / SecondsPerYear) + ", " + str(Year_True))
	
	if(Controller.Spinup_CC):
		Call_Daily_Input_Save = ((Year_True > (Controller.Year_Start_Offline-Controller.Year_Average_Offline)) and (Year_True <= Controller.Year_Start_Offline))
		Use_Daily_Input_Save = Year_True > Controller.Year_Start_Offline
		Spinup_CC_1 = ((StepOfYear == 1) and (Year_True == (Controller.Year_Start_Offline+1)))
		Spinup_CC_2 = ((StepOfYear == 1) and (Year_True == Controller.Number_Years_Spinup_BGC))
	else:
		Call_Daily_Input_Save = false
		Use_Daily_Input_Save = false
		Spinup_CC_1 = false
		Spinup_CC_2 = false
	
	var Year_Call_Accel = ((fmod(Year_True,Acceleration) == 0) or (Year_True == 1))
	var Year_Call_SMB = ((fmod(Year_True,SMB_Years) == 0) or (Year_True == 1))
	
	if(Controller.FLAG_ATMOSPHERE and Year_Call_Accel):
		Time_Call_Atmosphere = (fmod(Step,Step_Atmosphere) == 1 ) or (Step_Atmosphere == 1)
		Atmosphere_SOY = StepOfYear == 1
		Atmosphere_SOD = (fmod(StepOfYear,NStep_Day_Atmosphere) == 1) or (NStep_Day_Atmosphere == 1)
		Atmosphere_EOD = fmod(StepOfYear,NStep_Day_Atmosphere) == 0
		Atmosphere_EOM = (fmod(DayOfYear,DaysPerMonth) == 0) and Atmosphere_EOD
		Atmosphere_EOY = (fmod(DayOfYear,DaysPerYear) == 0) and Atmosphere_EOD
		Time_Out_Atmosphere = (fmod(Year_True,NYear_Out_Atmosphere) == 0) and (Current_Year > Year_Out_Start)
		Feedback_Save = Year_True == (Number_Of_Years/2.0) #"Save Fields"
		Feedback_Analysis = Year_True == Number_Of_Years #"Do Feedback Analysis", I guess this is some final process?
	else:
		Time_Call_Atmosphere = false
		Atmosphere_SOY = false
		Atmosphere_SOD = false
		Atmosphere_EOD = false
		Atmosphere_EOM = false
		Atmosphere_EOY = false
		Time_Out_Atmosphere = false
		Feedback_Save = false
		Feedback_Analysis = false
	
	if(Controller.FLAG_OCEAN and Year_Call_Accel):
		Time_Call_Ocean = (fmod(Step,Step_Ocean) == 1 ) or (Step_Ocean == 1)
		Ocean_SOY = StepOfYear == 1
		Ocean_SOD = (fmod(StepOfYear,NStep_Day_Ocean) == 1) or (NStep_Day_Ocean == 1)
		Ocean_EOD = fmod(StepOfYear,NStep_Day_Ocean) == 0
		Ocean_EOM = (fmod(DayOfYear,DaysPerMonth) == 0) and Ocean_EOD
		Ocean_EOY = (fmod(DayOfYear,DaysPerYear) == 0) and Ocean_EOD
		Time_Out_Ocean = (fmod(Year_True,NYear_Out_Ocean) == 0) and (Current_Year > Year_Out_Start)
		
	else:
		Time_Call_Ocean = false
		Ocean_SOY = false
		Ocean_SOD = false
		Ocean_EOD = false
		Ocean_EOM = false
		Ocean_EOY = false
		Time_Out_Ocean = false
	
	if(Controller.FLAG_BGC and Year_Call_Accel):
		Time_Call_BGC = (fmod(Step,Step_BGC) == 1 ) or (Step_BGC == 1)
		BGC_SOY = StepOfYear == 1
		BGC_SOD = (fmod(StepOfYear,NStep_Day_BGC) == 1) or (NStep_Day_BGC == 1)
		BGC_EOD = fmod(StepOfYear,NStep_Day_BGC) == 0
		BGC_EOM = (fmod(DayOfYear,DaysPerMonth) == 0) and BGC_EOD
		BGC_EOY = (fmod(DayOfYear,DaysPerYear) == 0) and BGC_EOD
		Time_Out_BGC = (fmod(Year_True,NYear_Out_BGC) == 0) and (Current_Year > Year_Out_Start)
		
	else:
		Time_Call_BGC = false
		BGC_SOY = false
		BGC_SOD = false
		BGC_EOD = false
		BGC_EOM = false
		BGC_EOY = false
		Time_Out_BGC = false
	
	if(Controller.FLAG_LAND and Year_Call_Accel):
		Time_Call_Land = (fmod(Step,Step_Land) == 1 ) or (Step_Land == 1)
		Land_SOY = StepOfYear == 1
		Land_SOD = (fmod(StepOfYear,NStep_Day_Land) == 1) or (NStep_Day_Land == 1)
		Land_EOD = fmod(StepOfYear,NStep_Day_Land) == 0
		Land_EOM = (fmod(DayOfYear,DaysPerMonth) == 0) and Land_EOD
		Land_EOY = (fmod(DayOfYear,DaysPerYear) == 0) and Land_EOD
		Time_Out_Land = (fmod(Year_True,NYear_Out_Land) == 0) and (Current_Year > Year_Out_Start)
		
	else:
		Time_Call_Land = false
		Land_SOY = false
		Land_SOD = false
		Land_EOD = false
		Land_EOM = false
		Land_EOY = false
		Time_Out_Land = false
	
	if(Controller.FLAG_SIC and Year_Call_Accel):
		Time_Call_SeaIce = (fmod(Step,Step_Sea_Ice) == 1 ) or (Step_Sea_Ice == 1)
		SeaIce_SOY = StepOfYear == 1
		SeaIce_SOD = (fmod(StepOfYear,NStep_Day_SeaIce) == 1) or (NStep_Day_SeaIce == 1)
		SeaIce_EOD = fmod(StepOfYear,NStep_Day_SeaIce) == 0
		SeaIce_EOM = (fmod(DayOfYear,DaysPerMonth) == 0) and SeaIce_EOD
		SeaIce_EOY = (fmod(DayOfYear,DaysPerYear) == 0) and SeaIce_EOD
		Time_Out_SeaIce = (fmod(Year_True,NYear_Out_BGC) == 0) and (Current_Year > Year_Out_Start)
		
	else:
		Time_Call_SeaIce = false
		SeaIce_SOY = false
		SeaIce_SOD = false
		SeaIce_EOD = false
		SeaIce_EOM = false
		SeaIce_EOY = false
		Time_Out_SeaIce = false
	
	if(Controller.FLAG_SMB and Year_Call_SMB):
		Time_Call_SMB = (fmod(Step,Step_SMB) == 1 ) or (Step_SMB == 1)
		SMB_SOY = StepOfYear == 1
		SMB_SOD = (fmod(StepOfYear,NStep_Day_SMB) == 1) or (NStep_Day_SMB == 1)
		SMB_EOD = fmod(StepOfYear,NStep_Day_SMB) == 0
		SMB_EOM = (fmod(DayOfYear,DaysPerMonth) == 0) and SMB_EOD
		SMB_EOY = (fmod(DayOfYear,DaysPerYear) == 0) and SMB_EOD
		Time_Out_SMB = (fmod(Year_True,NYear_Out_SMB) == 0) and (Current_Year > Year_Out_Start)
		
	else:
		Time_Call_SMB = false
		SMB_SOY = false
		SMB_SOD = false
		SMB_EOD = false
		SMB_EOM = false
		SMB_EOY = false
		Time_Out_SMB = false
	
	if(Controller.FLAG_BMB and Year_Call_Accel):
		Time_Call_BMB = (fmod(Step,Step_BMB) == 1 ) or (Step_BMB == 1)
		BMB_SOY = StepOfYear == 1
		BMB_SOD = (fmod(StepOfYear,NStep_Day_BMB) == 1) or (NStep_Day_BMB == 1)
		BMB_EOD = fmod(StepOfYear,NStep_Day_BMB) == 0
		BMB_EOM = (fmod(DayOfYear,DaysPerMonth) == 0) and BMB_EOD
		BMB_EOY = (fmod(DayOfYear,DaysPerYear) == 0) and BMB_EOD
		Time_Out_BMB = (fmod(Year_True,NYear_Out_BMB) == 0) and (Current_Year > Year_Out_Start)
		
	else:
		Time_Call_BMB = false
		BMB_SOY = false
		BMB_SOD = false
		BMB_EOD = false
		BMB_EOM = false
		BMB_EOY = false
		Time_Out_BMB = false
	
	if(Controller.FLAG_ICESHEET):
		Time_Call_Ice = fmod(Step + NStep_Day - 1, Step_Ice) == 0
		Time_Out_Ice = (fmod(Year_True,NYear_Out_Ice) == 0) and (Current_Year > Year_Out_Start)
	else:
		Time_Call_Ice = false
		Time_Out_Ice = false
	
	if(Controller.FLAG_GEO or (Controller.I_Fake_Geo == 1)):
		Time_Call_Geo = (StepOfYear == 1) and (fmod(Year_True,Number_Of_Years_Geo) == 0)
		Time_Out_Geo = (fmod(Year_True,NYear_Out_Geo) == 0) and (Current_Year > Year_Out_Start)
	else:
		Time_Call_Geo = false
		Time_Out_Geo = false
	
	Time_SOY = StepOfYear == 1
	BND_SOY = StepOfYear == 1
	
	#Seasons
	if(Year_Call_Accel):
		Time_Call_Clim = (fmod(Step, 1) == 0)
		if(NStep_Month == 0):
			Time_EOM = 0
		else:
			Time_EOM = (fmod(StepOfYear, NStep_Month) == 0)
		Time_EOY = (fmod(StepOfYear, NStep_Year) == 0)
	else:
		Time_Call_Clim = false
		Time_EOM = false
		Time_EOY = 0
	
	#Output
	Time_Out_CMN = (fmod(Year_True,NYear_Out_CMN) == 0) and (Current_Year >= Year_Out_Start)
	
	if(Time_SOY):
		#time series for geo
		Year_Out_TS_GEO = int(fmod(Year_True, NYear_Out_TS_GEO))
		if(Year_Out_TS_GEO == 0):
			Year_Out_TS_GEO = NYear_Out_TS_GEO
		if((Year_True == Number_Of_Years_Geo) or (Year_Out_TS_GEO == NYear_Out_TS_GEO)):
			Time_Out_TS_Geo = true
		else:
			Time_Out_TS_Geo = false
		@warning_ignore("integer_division")
		Year_Out_TS_GEO = Year_Out_TS_GEO / Number_Of_Years_Geo
		
		#time series for Climate (other than ice sheets and SMB)
		Year_Out_TS_CLIM = int(fmod(Year_True, NYear_Out_TS_Acceleration))
		if(Year_Out_TS_CLIM == 0):
			Year_Out_TS_CLIM = NYear_Out_TS_Acceleration
		if((Year_True == Number_Of_Years_Climate) or (Year_Out_TS_CLIM == NYear_Out_TS_Acceleration)):
			Time_Out_TS_Clim = true
		else:
			Time_Out_TS_Clim = false
		@warning_ignore("integer_division")
		Year_Out_TS_CLIM = Year_Out_TS_CLIM / Number_Of_Years_Climate
		
		#time series for SMB
		Year_Out_TS_SMB = int(fmod(Year_True, NYear_Out_TS_SMB))
		if(Year_Out_TS_SMB == 0):
			Year_Out_TS_SMB = NYear_Out_TS_SMB
		if((Year_True == Number_Of_Years_Geo) or (Year_Out_TS_SMB == NYear_Out_TS_SMB)):
			Time_Out_TS_SMB = true
		else:
			Time_Out_TS_SMB = false
		@warning_ignore("integer_division")
		Year_Out_TS_SMB = max(1,Year_Out_TS_SMB / Year_SMB)
		
		#time series for ice sheets
		Year_Out_TS = int(fmod(Year_True, NYear_Out_TS))
		if(Year_Out_TS == 0):
			Year_Out_TS = NYear_Out_TS
		if((Year_True == Number_Of_Years) or (Year_Out_TS == NYear_Out_TS)):
			Time_Out_TS = true
		else:
			Time_Out_TS = false
		@warning_ignore("integer_division")
		Year_Out_TS = Year_Out_TS / Number_Of_Years
	
	if((Geo_Years >= 1) and (Year_True == 1)):
		Year_Out_TS_GEO = 1
	
	if((Acceleration > 1) and (Year_True == 1)):
		Year_Out_TS_CLIM = 1
		Year_Out_TS_SMB = 1
	
	Write_Restart = false
	if (Controller.i_write_restart == 0):
		#Only write at the end
		Write_Restart = (fmod(StepOfYear,NStep_Year) == 0) and (Year_True == Number_Of_Years)
	elif (Controller.i_write_restart == 1):
		#Regular frequency writing
		Write_Restart = (fmod(StepOfYear,NStep_Year) == 0) and ((fmod(Year_True, Controller.n_year_write_restart) == 0) or ((Year_True == Number_Of_Years)))
	elif (Controller.i_write_restart == 2):
		#Specified times for writing
		for i in range(Controller.years_write_restart):
			if (fmod(StepOfYear,NStep_Year) == 0) and (Controller.years_write_restart[i] == Current_Year):
				Write_Restart = true
	
	print("step = %s, year = %s, year_clim = %s, month = %s \n" % [Step,Year_True,Year_Climate,Month],"year_call_accel = %s\nDayOfYear = %s, StepOfYear = %s, time_SOY = %s" % [Year_Call_Accel,DayOfYear,StepOfYear,Time_SOY]) #truncated output checker. Expand if there are issues.
