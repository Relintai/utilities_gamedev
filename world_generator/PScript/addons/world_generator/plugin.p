tool;
extends EditorPlugin;

const bool USE_BOTTOM_PANEL = false;

PackedScene editor_packed_scene = preload("res://addons/world_generator/ui/MainScreen.tscn");
Node editor_scene = null;

ToolButton tool_button = null;

void edit_resource(Resource resource) {
	get_editor_interface().edit_resource(resource);
}

void _enter_tree() {
	editor_scene = editor_packed_scene.instance();
	editor_scene.set_plugin(this);
	editor_scene.hide();
	
	if USE_BOTTOM_PANEL {
		tool_button = add_control_to_bottom_panel(editor_scene, "World Editor");
		tool_button.hide();
	} else {
		get_editor_interface().get_editor_viewport().add_child(editor_scene);
	}
}

void disable_plugin() {
	if USE_BOTTOM_PANEL {
		//remove_control_from_bottom_panel(editor_scene);
	}
	
	if editor_scene {
		editor_scene.queue_free();
		editor_scene = null;
	}
}

bool handles(Object object) {
	return object is WorldGenWorld;
}

void edit(Object object) {
	#if editor_scene:
	#	make_bottom_panel_item_visible(editor_scene)

	if object is WorldGenWorld {
		WorldGenWorld wgw = object as WorldGenWorld;
		editor_scene.set_wgworld(wgw);
		get_editor_interface().set_main_screen_editor("World");
	}
}

void make_visible(bool visible) {
	if USE_BOTTOM_PANEL {
		if tool_button {
			if visible {
				tool_button.show();
			} else {
				#if tool_button.pressed:
				#	tool_button.pressed = false

				if !tool_button.pressed {
					tool_button.hide();
				}
			}
		}
	} else {
		if editor_scene {
			editor_scene.set_visible(visible);
		}
	}
}

Texture get_plugin_icon() {
	if USE_BOTTOM_PANEL {
		return null;
	} else {
		return get_editor_interface().get_base_control().get_theme_icon(@"NavigationPolygon", @"EditorIcons");
	}
}

String get_plugin_name() {
	return "World";
}

bool has_main_screen() {
	if USE_BOTTOM_PANEL {
		return false;
	} else {
		return true;
	}
}

