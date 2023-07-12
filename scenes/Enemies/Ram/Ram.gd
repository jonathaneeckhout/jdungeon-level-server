extends "res://scripts/entity.gd"

const CLASS = "Ram"


func _ready():
	super()
	$Interface/Name.text = CLASS
