class_name ResourceSource
extends Node3D
var item_id: String = "olive"
var stock := Inventory.new()
var title: String = "Orchard"
var label: Label3D
var harvest_seconds: float = 1.0
var renewable: bool = false
var regrow_timer: float = 0
var enabled: bool = true

func _ready() -> void:
	stock.capacity = 10000
	stock.add(item_id,60)
	BlockoutKit.box(self,Vector3(0,0.3,0),Vector3(2,0.6,2),Color("836349"))
	BlockoutKit.sphere(self,Vector3(0,1,0),Vector3(1.2,0.8,1.1),Color("6e8150") if item_id=="olive" else Color("929591"))
	label = BlockoutKit.label(self,"",Vector3(0,2.2,0),26)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stock.changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	label.text = "%s · %d\nU  Gather"%[title,stock.count(item_id)]

func gather(destination: Inventory, amount: int = 1) -> bool:
	return stock.transfer_to(destination,item_id,amount)

func _process(delta: float) -> void:
	if not enabled or not renewable or stock.count(item_id)>0: return
	regrow_timer += delta
	if regrow_timer>=15:
		regrow_timer = 0
		stock.add(item_id,20)
