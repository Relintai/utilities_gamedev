tool;
extends EditorPlugin;

Node _dock = null;

void _enter_tree() {
	PackedScene dock_scene = load("res://addons/zylann.editor_debugger/dock.tscn");
	_dock = dock_scene.instance();
	_dock.connect("node_selected", this, "_on_EditorDebugger_node_selected");
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock);
	
	EditorSettings editor_settings = get_editor_interface().get_editor_settings();
	editor_settings.connect("settings_changed", this, "_on_EditorSettings_settings_changed");
	call_deferred("_on_EditorSettings_settings_changed");
}

void _exit_tree() {
	remove_control_from_docks(_dock);
	_dock.free();
	_dock = null;
}

void _on_EditorDebugger_node_selected(Node node) {
	if _dock.is_inspection_enabled() {
		# Oops.
		get_editor_interface().inspect_object(node);
	}
}

void _on_EditorSettings_settings_changed() {
	EditorSettings editor_settings = get_editor_interface().get_editor_settings();
	
	#bool enable_rl = editor_settings.get_setting("docks/scene_tree/draw_relationship_lines");
	#Color rl_color = editor_settings.get_setting("docks/scene_tree/relationship_line_color");
	
	Tree tree = _dock.get_tree_view();
	
	tree.add_theme_constant_override("draw_relationship_lines", 1);
	tree.add_theme_constant_override("draw_guides", 0);
	
//	if enable_rl {
//		tree.add_theme_constant_override("draw_relationship_lines", 1);
//		tree.add_theme_color_override("relationship_line_color", rl_color);
//		tree.add_theme_constant_override("draw_guides", 0);
//	} else {
//		tree.add_theme_constant_override("draw_relationship_lines", 0);
//		tree.add_theme_constant_override("draw_guides", 1);
//	}
}
