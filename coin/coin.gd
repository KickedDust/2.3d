extends Area3D


signal collected(coin)


var taken := false


func _ready() -> void:
	add_to_group("objective_targets")


func _on_coin_body_enter(body):
	if not taken and body is Player:
		$Animation.play(&"take")
		taken = true
		remove_from_group("objective_targets")
		# We've already checked whether the colliding body is a Player, which has a `coins` property.
		# As a result, we can safely increment its `coins` property.
		body.coins += 1
		if body.has_method("restore_power"):
			body.restore_power(5.0)
		emit_signal(&"collected", self)


func is_objective_active() -> bool:
	return not taken
