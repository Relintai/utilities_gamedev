tool
extends EditorPlugin

const USE_BOTTOM_PANEL = false

var SWorldGeneratorSettings = preload("res://addons/world_generator/resources/world_generator_settings.gd")

var SWorldGenBaseResource = preload("res://addons/world_generator/resources/world_gen_base_resource.gd")
var SWorldGenWorld = preload("res://addons/world_generator/resources/world_gen_world.gd")
var SContinent = preload("res://addons/world_generator/resources/continent.gd")
var SZone = preload("res://addons/world_generator/resources/zone.gd")
var SSubZone = preload("res://addons/world_generator/resources/subzone.gd")

var editor_packed_scene = preload("res://addons/world_generator/ui/MainScreen.tscn")
var editor_scene : Node = null

var tool_button : ToolButton = null

func edit_resource(resource: Resource) -> void:
	get_editor_interface().edit_resource(resource)

func _enter_tree():
#	add_custom_type("WorldGeneratorSettings", "Resource", SWorldGeneratorSettings, null)
#
#	add_custom_type("WorldGenBaseResource", "Resource", SWorldGenBaseResource, null)
#	add_custom_type("WorldGenWorld", "WorldGenBaseResource", SWorldGenWorld, null)
#	add_custom_type("Continent", "WorldGenBaseResource", SContinent, null)
#	add_custom_type("Zone", "WorldGenBaseResource", SZone, null)
#	add_custom_type("SubZone", "WorldGenBaseResource", SSubZone, null)

	editor_scene = editor_packed_scene.instance()
	editor_scene.set_plugin(self)
	editor_scene.hide()
	
	if USE_BOTTOM_PANEL:
		tool_button = add_control_to_bottom_panel(editor_scene, "World Editor")
		tool_button.hide()
	else:
		get_editor_interface().get_editor_viewport().add_child(editor_scene)

func disable_plugin() -> void:
#	remove_custom_type("WorldGeneratorSettings")
#
#	remove_custom_type("WorldGenBaseResource")
#	remove_custom_type("WorldGenWorld")
#	remove_custom_type("Continent")
#	remove_custom_type("Zone")
#	remove_custom_type("SubZone")

	if USE_BOTTOM_PANEL:
		#remove_control_from_bottom_panel(editor_scene)
		pass
	
	if editor_scene:
		editor_scene.queue_free()
		editor_scene = null
	

func handles(object):
	return object is WorldGenWorld

func edit(object):
	#if editor_scene:
	#	make_bottom_panel_item_visible(editor_scene)

	if object is WorldGenWorld:
		var wgw : WorldGenWorld = object as WorldGenWorld
		editor_scene.set_wgworld(wgw)
		get_editor_interface().set_main_screen_editor("World")

func make_visible(visible):
	if USE_BOTTOM_PANEL:
		if tool_button:
			if visible:
				tool_button.show()
			else:
				#if tool_button.pressed:
				#	tool_button.pressed = false

				if !tool_button.pressed:
					tool_button.hide()
	else:
		if editor_scene:
			editor_scene.set_visible(visible)

func get_plugin_icon():
	if USE_BOTTOM_PANEL:
		return null
	else:
		return get_editor_interface().get_base_control().get_theme_icon(@"NavigationPolygon", @"EditorIcons")

func get_plugin_name():
	return "World"

func has_main_screen():
	if USE_BOTTOM_PANEL:
		return false
	else:
		return true


