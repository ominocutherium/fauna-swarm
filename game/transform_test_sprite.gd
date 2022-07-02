extends Sprite

export(Vector2) var basis_x : Vector2
export(Vector2) var basis_y : Vector2

func _ready() -> void:
	var tf := Transform2D()
	tf.x = basis_x
	tf.y = basis_y
	tf.origin = position
	transform = tf
	print("Affine inverse of transform {0}: {1}".format([tf,tf.affine_inverse()]))
