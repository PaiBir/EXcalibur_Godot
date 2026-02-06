class_name CLIMBER_X_ATMO
extends Node

var atmosphere_parameters : ATM_PARAM
var atm_grid : GRID

var pl : float
var zl : float

var Atm_CO2 : float #ppmv
var Equivalent_CO2 : float #ppmv
var Atm_CH4 : float #ppb
var Atm_N2O : float #ppb
var Atm_CFC11 : float #ppt
var Atk_CFC12 : float #ppt

var Hadley_Cell_Width : float #radians
var InterTropicalConvergenceZone_Position : float #radians

var eccentricity : float
var precession : float
var obliquity : float

var t2m_glob_ann : float = 0
var dt2m_glob_ann_cum : float = 0

func Flux(fax, fay, tp, q3, d3, cam, diffusiveXenergy, diffusiveYenergy, diffusiveXwater, diffusiveYwater, diffusiveXdust, diffusiveYdust, convectiveEnergy, convectiveWater, convectiveDust, convectiveCO2, fluxXenergy, fluxXwater, fluxXdust, fluxXCO2, fluxYenergy, fluxYwater, fluxYdust, fluxYCO2, fdXenergy, fdXwater, fdXdust, fdXCO2, fdYenergy, fdYwater, fdYdust, fdYCO2):
	var i : int
	var k : int
	var imi : int
	var jmi : int
	var tpup : float
	var qup : float
	var dup : float
	var cup : float
	var dpl_x : float
	var dpl_y : float
	var tp_ijk : float
	var tp_i1jk : float
	var tp_ij1k : float
	var q3_ijk : float
	var q3_i1jk : float
	var q3_ij1k : float
	var d3_ijk : float
	var d3_i1jk : float
	var d3_ij1k : float
	var c3_ij : float
	var c3_i1j : float
	var c3_ij1 : float
	var fax_ijk : float
	var fay_ijk : float
	
	for j in (range(1,atm_grid.jm+1)):
		pass
