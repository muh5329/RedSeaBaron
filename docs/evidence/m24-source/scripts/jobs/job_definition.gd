class_name JobDefinition
extends Resource
@export var title: String = "Transport goods"
@export var kind: String = "Transport"
@export var item_id: String = "olive"
@export var amount: int = 5
@export var work_seconds: float = 1.5
var source: Node3D
var destination: Storage
var contract: DeliveryContract
var shop: Shop
