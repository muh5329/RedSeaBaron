class_name Storage
extends Node3D
var inventory := Inventory.new()
var title: String = "Warehouse"
var kind: String = "storage"
var station_id: String = ""
var label: Label3D

func _ready() -> void:
	inventory.capacity = 1000
	BlockoutKit.box(self,Vector3(0,0.6,0),Vector3(2,1.2,1.3),Color("a3754b"))
	BlockoutKit.box(self,Vector3(0,1.25,0),Vector3(2.2,0.15,1.5),Color("d0b98f"))
	label = BlockoutKit.label(self,title+"\nU  Use",Vector3(0,2.25,0),26)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visible = false
