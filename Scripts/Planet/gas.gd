class_name AtmoGas
extends Node

var Gas : Dictionary
var Pressure : float = 0

func _init(_gas : Dictionary, _pressure : float) -> void:
	Gas = _gas
	Pressure = _pressure
