extends Node


const HANDLERS_BY_EVENT = {
	"order_move":"_handle_order_move",
	"order_hold":"_handle_order_hold",
	"order_capture_attack":"_handle_order_capture",
	"order_attack":"_handle_order_attack",
	"order_claim":"_handle_order_claim",
}


func _process(delta: float) -> void:
	for action_name in HANDLERS_BY_EVENT:
		if Input.is_action_just_released(action_name):
			call(HANDLERS_BY_EVENT[action_name])


func _handle_order_move() -> void:
	print("Move order pressed.")


func _handle_order_hold() -> void:
	print("Hold order pressed.")


func _handle_order_attack() -> void:
	print("Attack order pressed.")


func _handle_order_capture() -> void:
	print("Capture order pressed.")


func _handle_order_claim() -> void:
	print("Claim order pressed.")
