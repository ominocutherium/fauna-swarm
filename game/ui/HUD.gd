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

extends Control

class_name HeadsUpDisplay


signal request_unit_upgrade
signal request_queue_item_cancel
signal request_abandon_game
signal request_save_and_quit


export(NodePath) var upgrade_unit_disp_path : NodePath
export(NodePath) var unit_disp_path : NodePath
export(NodePath) var multi_unit_disp_path : NodePath
export(NodePath) var building_disp_path : NodePath
export(NodePath) var pause_button_path : NodePath
export(NodePath) var menu_button_path : NodePath
export(NodePath) var menu_popup_path : NodePath
export(NodePath) var order_buttons_path : NodePath
export(NodePath) var order_modal_panel_path : NodePath
export(NodePath) var order_modal_label_path : NodePath


var selected_unit_identifier : int = -1
var selected_units_group_identifiers := []
var selected_building_identifier : int = -1


func _ready() -> void:
	_clear_everything()


func _input(event: InputEvent) -> void:
	for action_name in ["upgrade_unit_opt1","upgrade_unit_opt2"]:
		if Input.is_action_just_released(action_name) and selected_unit_identifier >= 0:
			emit_signal("request_unit_upgrade",selected_unit_identifier,action_name.substr(16).to_int()-1)


func _on_UpgradeUnit_pressed() -> void:
	get_node(upgrade_unit_disp_path).show()
	get_node(unit_disp_path).hide()
	# TODO: gray out buttons if lacking leaves


func _on_upgrade_option_pressed(option: int) -> void:
	get_node(upgrade_unit_disp_path).hide()
	get_node(unit_disp_path).show()
	emit_signal("request_unit_upgrade",selected_unit_identifier,option)


func _on_upgrade_unit_cancel_pressed() -> void:
	get_node(upgrade_unit_disp_path).hide()
	get_node(unit_disp_path).show()


func _on_TopOfQueue_request_top_queue_cancel() -> void:
	if selected_building_identifier >= 0:
		emit_signal("request_queue_item_cancel",selected_building_identifier,0)


func _on_later_queue_request_queue_cancel(idx:int) -> void:
	if selected_building_identifier >= 0:
		emit_signal("request_queue_item_cancel",selected_building_identifier,idx)


func units_selected(list_of_units : Array) -> void:
	if list_of_units.size() == 0:
		return
	elif list_of_units.size() == 1:
		_disp_selected_unit(list_of_units[0])
	else:
		_disp_group_of_units(list_of_units)


func building_selected(building : SavedBuilding) -> void:
	_hide_all_on_left()
	var building_data := StaticData.get_building(building.building_type)
	for child in get_node(building_disp_path).get_node("RestOfQueue").get_children():
		child.queue_free()
	get_node(building_disp_path).get_node("Name").text = tr(building_data.name_key)
	var tex := AtlasTexture.new()
	tex.atlas = load(building_data.texture_path)
	tex.region = Rect2(building_data.texture_pos_x,building_data.texture_pos_y,building_data.texture_size_x,building_data.texture_size_y)
	get_node(building_disp_path).get_node("H1/TextureRect").texture = tex
	get_node(building_disp_path).get_node("H1/TopOfQueue/V/Desc").text = tr(building_data.short_desc_key)
	if building.queue_items.size() > 0:
		get_node(building_disp_path).get_node("H1/TopOfQueue/V/H/TextureRect").texture = load("res://icon.png")
		get_node(building_disp_path).get_node("H1/TopOfQueue/V/H/ProgressBar").max_value = 5.0
		get_node(building_disp_path).get_node("H1/TopOfQueue/V/H/ProgressBar").value = 3.0
		get_node(building_disp_path).get_node("H1/TopOfQueue/V/H/TextureRect").show()
#		get_node(building_disp_path).get_node("H1/Top/V/H/ProgressBar").show()
	else:
		get_node(building_disp_path).get_node("H1/TopOfQueue/V/H/TextureRect").hide()
		get_node(building_disp_path).get_node("H1/TopOfQueue/V/H/ProgressBar").hide()
	# TODO: count down progress on queue items in _process once event system is implemented
	for i in range(1,int(min(building.queue_items.size(),8))):
		var queue_item_disp := LaterBuildingQueueButton.new()
		queue_item_disp.texture = load("res://icon.png")
		get_node(building_disp_path).get_node("RestOfQueue").add_child(queue_item_disp)
		if building.faction == StaticData.engine_keys_to_faction_ids.purity:
			queue_item_disp.connect("request_queue_cancel",self,"_on_later_queue_request_queue_cancel",[i])
	get_node(order_buttons_path).hide()
	get_node(building_disp_path).show()


func _disp_selected_unit(unit_identifier:int) -> void:
	var unit = GameState.get_unit(unit_identifier)
	_hide_all_on_left()
	# TODO: get strings from static data and translate them
	get_node(unit_disp_path).get_node("Name").text = "{0} {1}".format([tr(StaticData.get_faction(unit.faction).name_key),tr(StaticData.get_species(unit.species).name_key)])
	var sp_disp = StaticData.get_species_display(unit.species)
	var species_atlas_tex : Texture = load(StaticData.get_species_display(unit.species).purity_tex_path)
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = species_atlas_tex
	var desc_string : String
	match unit.faction:
		StaticData.engine_keys_to_faction_ids.purity:
			atlas_texture.region = Rect2(sp_disp.purity_pos_x,sp_disp.purity_pos_y,sp_disp.sprite_size_h,sp_disp.sprite_size_v)
			desc_string = StaticData.get_species(unit.species).desc_short_key
		StaticData.engine_keys_to_faction_ids.specter:
			atlas_texture.region = Rect2(sp_disp.specter_pos_x,sp_disp.specter_pos_y,sp_disp.sprite_size_h,sp_disp.sprite_size_v)
			desc_string = tr("BASE_GAME_CORRUPTED_ANIMAL_TEMPLATE").format([tr(StaticData.get_faction(unit.faction).name_key),tr(StaticData.get_species(unit.species).name_key)])
	get_node(unit_disp_path).get_node("H1/C/V/TextureRect").texture = atlas_texture
	get_node(unit_disp_path).get_node("CurrentHealth").max_value = unit.get_maximum_health()
	get_node(unit_disp_path).get_node("CurrentHealth").value = unit.current_health
	get_node(unit_disp_path).get_node("H1/C2/ShortDesc").text = desc_string
	get_node(unit_disp_path).get_node("TechniqueName").text = tr(StaticData.get_species(unit.species).attack_name_key)
	get_node(unit_disp_path).get_node("TechniqueDesc").text = tr("HUD_SELUNIT_EXAMPLE_TECHDESC")
	if unit.faction == StaticData.engine_keys_to_faction_ids.purity and unit.upgrade_type == -1:
		get_node(unit_disp_path).get_node("H1/C/V/UpgradeUnit").show()
	else:
		get_node(unit_disp_path).get_node("H1/C/V/UpgradeUnit").hide()
	if unit.faction == StaticData.engine_keys_to_faction_ids.purity:
		get_node(order_buttons_path).show()
	else:
		get_node(order_buttons_path).hide()
	get_node(unit_disp_path).show()


func _disp_group_of_units(list_of_units:Array) -> void:
	# TODO: handle factions
	var species_count_by_species_id := {}
	for child in get_node(multi_unit_disp_path).get_children():
		if child.get_child_count() > 0:
			for sub_child in child.get_children():
				sub_child.queue_free()
	for u in list_of_units:
		var unit := GameState.get_unit(u) as SavedUnit
		if not unit.species in species_count_by_species_id:
			species_count_by_species_id[unit.species] = 1
		else:
			species_count_by_species_id[unit.species] += 1
	var species_in_group := species_count_by_species_id.keys().duplicate()
	var key_id : int = 0
	for j in range(int(ceil(0.5*species_in_group.size()))):
		if key_id >= species_in_group.size():
			break
		for i in range(2):
			var texrect := TextureRect.new()
			var spec_tex := AtlasTexture.new()
			texrect.rect_min_size = Vector2(36,36)
			texrect.expand = true
			texrect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			var count := Label.new()
			var spec : int = species_in_group[key_id]
			var sp_disp = StaticData.get_species_display(spec)
			spec_tex.atlas = load(sp_disp.purity_tex_path)
			spec_tex.region = Rect2(sp_disp.purity_pos_x,sp_disp.purity_pos_y,sp_disp.sprite_size_h,sp_disp.sprite_size_v)
			count.text = str(species_count_by_species_id[spec])
			get_node(multi_unit_disp_path).get_child(j).add_child(texrect)
			get_node(multi_unit_disp_path).get_child(j).add_child(count)
			texrect.texture = spec_tex
			key_id += 1
			if key_id >= species_in_group.size():
				break
	_hide_all_on_left()
	get_node(multi_unit_disp_path).show()


func _hide_all_on_left() -> void:
	get_node(upgrade_unit_disp_path).hide()
	get_node(unit_disp_path).hide()
	get_node(multi_unit_disp_path).hide()
	get_node(building_disp_path).hide()


func _on_order_input_mode_order_in_progress(order_type:int,addl_param=null) -> void:
	match order_type:
		UnitManager.OrderTypes.HOLD_POS:
			return
		UnitManager.OrderTypes.ATTACK_OBJ:
			get_node(order_modal_label_path).text = tr("HUD_ORDER_MODAL_AMOVE_IN_PROGRESS")
			get_node(order_modal_panel_path).show()
		UnitManager.OrderTypes.MOVE_TO_POS:
			get_node(order_modal_label_path).text = tr("HUD_ORDER_MODAL_MOVE_IN_PROGRESS")
			get_node(order_modal_panel_path).show()
		UnitManager.OrderTypes.ATTACK_POS:
			get_node(order_modal_label_path).text = tr("HUD_ORDER_MODAL_AMOVE_IN_PROGRESS")
			get_node(order_modal_panel_path).show()
		UnitManager.OrderTypes.CLAIM_OBJ:
			get_node(order_modal_label_path).text = tr("HUD_ORDER_MODAL_CLAIM_IN_PROGRESS")
			get_node(order_modal_panel_path).show()
		UnitManager.OrderTypes.BUILD_OBJ:
			if addl_param != null and typeof(addl_param) == TYPE_INT:
				var building_tr_string : String = tr(StaticData.get_building(addl_param).name_key)
				get_node(order_modal_label_path).text = tr("HUD_ORDER_MODAL_BUILD_CHOOSE_LOCATION").format([building_tr_string])
				get_node(order_modal_panel_path).show()
			else:
				get_node(order_modal_label_path).text = tr("HUD_ORDER_MODAL_BUILD_CHOOSE_BUILDING")
				get_node(order_modal_panel_path).show()
		UnitManager.OrderTypes.CAPTURE_OBJ:
			get_node(order_modal_label_path).text = tr("HUD_ORDER_MODAL_CMOVE_IN_PROGRESS")
			get_node(order_modal_panel_path).show()
		UnitManager.OrderTypes.HEAL:
			get_node(order_modal_label_path).text = tr("HUD_ORDER_MODAL_HEAL_IN_PROGRESS")
			get_node(order_modal_panel_path).show()


func _on_order_input_mode_order_invalidated() -> void:
	get_node(order_modal_panel_path).hide()


func _on_order_input_mode_order_cleared() -> void:
	get_node(order_modal_panel_path).hide()
	


func _on_menu_pressed() -> void:
	get_tree().paused = false
	$Menu.show()


func _on_pause_resume_pressed() -> void:
	if get_tree().paused:
		get_tree().paused = false
		get_node(pause_button_path).text = tr("GAME_PAUSE_BUTTON")
	else:
		get_tree().paused = true
		get_node(pause_button_path).text = tr("GAME_UNPAUSE_BUTTON")


func _on_settings_pressed() -> void:
	$Settings.popup()


func _on_resume_pressed() -> void:
	$Menu.hide()
	get_tree().paused = false


func _on_concede_pressed() -> void:
	$ConcedeDialog.popup()


func _on_concede_accepted() -> void:
	emit_signal("request_abandon_game")


func _on_menu_save_and_quit_pressed() -> void:
	emit_signal("request_save_and_quit")


func _clear_everything() -> void:
	get_node(order_modal_panel_path).hide()
	get_node(unit_disp_path).hide()
	get_node(order_buttons_path).hide()
