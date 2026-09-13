class_name JobRoutine
extends Resource
@export var id: String = "harvest_market"
@export var title: String = "Harvest and stock market"
@export var steps: Array[String] = ["Farm","ShopKeep"]
@export var repeat: bool = true
