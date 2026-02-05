tool;
extends EditorPlugin;

const Script DataManagerAddonSettings = preload("res://addons/data_manager/resources/data_manager_addon_settings.p");
const PackedScene _main_panel = preload("res://addons/data_manager/panels/MainPanel.tscn");

Texture _script_icon = null;

DataManagerAddonSettings settings = null;

Control _main_panel_instance;

void _enter_tree() {
	load_settings();
	
	_main_panel_instance = _main_panel.instance() as Control;
	_main_panel_instance.set_plugin(this);
	_main_panel_instance.connect("inspect_data", this, "inspect_data");

	get_editor_interface().get_editor_viewport().add_child(_main_panel_instance);

	make_visible(false);
}

void _exit_tree() {
	_main_panel_instance.queue_free();
}

bool has_main_screen() {
	return true;
}

void make_visible(bool visible) {
	if visible {
		_main_panel_instance.show();
	} else {
		_main_panel_instance.hide();
	}
}
Texture get_plugin_icon() {
	if !_script_icon {
		_script_icon = get_editor_interface().get_base_control().get_theme_icon("ThemeSelectAll", "EditorIcons");
	}
	
	return _script_icon;
}

String get_plugin_name() {
	return "Data";
}

void inspect_data(Resource data) {
	get_editor_interface().inspect_object(data);
}

void load_settings() {
	settings = DataManagerAddonSettings.new();
	settings.load_from_project_settings();
}
