class_name JobExecutor
extends RefCounted
## Transactional job operations are independent of worker locomotion/AI.
var job: JobDefinition
var acquired: bool = false
var delivered: bool = false
var failure: String = ""

func acquire(cargo: Inventory) -> bool:
	failure = ""
	if acquired: return true
	if job==null or not is_instance_valid(job.source):
		failure = "Source unavailable"
		return false
	if job.contract:
		acquired = job.contract.accept(cargo)
	elif job.source is ResourceSource:
		acquired = job.source.gather(cargo,job.amount)
	elif job.source is Storage:
		acquired = job.source.inventory.transfer_to(cargo,job.item_id,job.amount)
	if not acquired: failure = "Source empty or cargo full"
	return acquired

func deliver(cargo: Inventory) -> bool:
	failure = ""
	if delivered: return true
	if not acquired or not is_instance_valid(job.destination):
		failure = "Destination unavailable"
		return false
	if job.contract:
		delivered = job.contract.deliver(cargo)
	elif job.shop:
		delivered = job.shop.sell(cargo,job.item_id,job.amount)
	else:
		delivered = cargo.transfer_to(job.destination.inventory,job.item_id,job.amount)
	if not delivered: failure = "Destination full or cargo missing"
	return delivered
