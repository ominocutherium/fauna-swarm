# This file is a part of "Fauna Swarm", a game produced
# for "RTS Jam 1998" running from June 24th-July 28th on itch:
# <https://itch.io/jam/rts-jam-1998>

# A copy of the Godot 3.x editor is required to export this game.
# See <https://godotengine.org/license> for information about how
# Godot Engine is licensed.

# Gameplay code Copyright (C) 2022 ominocutherium and contributors

# The base game (but not the assets therein, which are licensed separately)
# is free software: you can redistribute it and/or modify it under the terms
# of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

extends Node2D

export(Texture) var texture setget set_texture


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
		texture.paint_layout()

func _on_texture_updated() -> void:
	update()
