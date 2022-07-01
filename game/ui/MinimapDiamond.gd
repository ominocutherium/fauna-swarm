extends Node2D

export(Texture) var texture


onready var minimap_diamond_points := [
	Vector2(600,500),
	Vector2(400,600),
	Vector2(200,500),
	Vector2(400,400),
]

func _ready() -> void:
	update()

func _draw() -> void:
	draw_colored_polygon(PoolVector2Array(minimap_diamond_points),Color.white,PoolVector2Array([Vector2(1,0.5),Vector2(0.5,1),Vector2(0,0.5),Vector2(0.5,0)]),texture)

func set_texture(tex:Texture) -> void:
	texture = tex
	if texture is MinimapTexture:
		texture.connect("texture_updated",self,"_on_texture_updated")

func _on_texture_updated() -> void:
	update()
