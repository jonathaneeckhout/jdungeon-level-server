extends "res://scripts/entity.gd"

const CLASS = "Sheep"


func _ready():
	super()
	$Interface/Name.text = CLASS
