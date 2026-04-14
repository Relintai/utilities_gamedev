tool;
extends EditorPlugin;

PanelContainer panel1;
PanelContainer panel2;

Array pids = Array();

void _enter_tree() {
	Node editor_node = get_tree().get_root().get_child(0);
	Control gui_base = editor_node.get_gui_base();
	Texture icon_transition = gui_base.get_theme_icon("TransitionSync", "EditorIcons"); #ToolConnect
	Texture icon_transition_auto = gui_base.get_theme_icon("TransitionSyncAuto", "EditorIcons");
	Texture icon_load = gui_base.get_theme_icon("Load", "EditorIcons");
	
	panel2 = _add_tooblar_button("_loaddir_pressed", icon_load, icon_load);
	panel1 = _add_tooblar_button("_multirun_pressed", icon_transition, icon_transition_auto);
	
	_add_setting("debug/multirun/number_of_windows", TYPE_INT, 2);
	_add_setting("debug/multirun/window_distance", TYPE_INT, 1270);
	_add_setting("debug/multirun/add_custom_args", TYPE_BOOL, true);
	_add_setting("debug/multirun/first_window_args", TYPE_STRING, "listen");
	_add_setting("debug/multirun/other_window_args", TYPE_STRING, "join");
}

void _multirun_pressed() {
	int window_count = ProjectSettings.get_setting("debug/multirun/number_of_windows");
	int window_dist = ProjectSettings.get_setting("debug/multirun/window_distance");
	bool add_custom_args = ProjectSettings.get_setting("debug/multirun/add_custom_args");
	String first_args = ProjectSettings.get_setting("debug/multirun/first_window_args");
	String other_args = ProjectSettings.get_setting("debug/multirun/other_window_args");
	
	Array commands = ["--position", "50,10"];
	
	if first_args && add_custom_args {
		foreach String arg in first_args.split(" ") {
			commands.push_front(arg);
		}
	}
	
	String main_run_args = ProjectSettings.get_setting("editor/main_run_args");
	
	if main_run_args != first_args {
		ProjectSettings.set_setting("editor/main_run_args", first_args);
	}
	
	EditorInterface interface = get_editor_interface();
	interface.play_main_scene();
	
	if main_run_args != first_args {
		ProjectSettings.set_setting("editor/main_run_args", main_run_args);
	}
	
	kill_pids();
	
	for (int i = 0; i < window_count-1; ++i) {
		commands = ["--position", str(50 + (i+1) * window_dist) + ",10"];
		if other_args && add_custom_args {
			foreach String arg in other_args.split(" ") {
				commands.push_front(arg);
			}
		}
		pids.append(OS.execute(OS.get_executable_path(), commands, false));
	}
}

void _loaddir_pressed() {
	OS.shell_open(OS.get_user_data_dir());
}

void _exit_tree() {
	_remove_panels();
	kill_pids();
}

void kill_pids() {
	foreach Variant pid in pids {
		OS.kill(pid);
	}
	pids.clear();
}

void _remove_panels() {
	if panel1 {
		remove_control_from_container(CONTAINER_TOOLBAR, panel1);
		panel1.free();
	}
	
	if panel2 {
		remove_control_from_container(CONTAINER_TOOLBAR, panel2);
		panel2.free();
	}
}

void _unhandled_input(InputEvent event) {
	if event is InputEventKey {
		if event.pressed and event.scancode == KEY_F4 {
			_multirun_pressed();
		}
	}
}

PanelContainer _add_tooblar_button(String action, Texture icon_normal, Texture icon_pressed) {
	PanelContainer panel = PanelContainer.new();
	TextureButton b = TextureButton.new();
	b.texture_normal = icon_normal;
	b.texture_pressed = icon_pressed;
	b.connect("pressed", this, action);
	panel.add_child(b);
	add_control_to_container(CONTAINER_TOOLBAR, panel);
	return panel;
}

void _add_setting(String name, int type, Variant value) {
	if ProjectSettings.has_setting(name) {
		return;
	}
	
	ProjectSettings.set(name, value);
	
	Dictionary property_info = |{
		"name": name,
		"type": type
	}|;
	
	ProjectSettings.add_property_info(property_info);
}
