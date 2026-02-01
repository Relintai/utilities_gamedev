tool;
extends EditorPlugin;

const Script TranslationEditor = preload("./translation_editor.p");
const PackedScene TranslationEditorScene = preload("./translation_editor.tscn");
const Script Logger = preload("./util/logger.p");

const Dictionary _default_settings = |{
	"translation_editor/string_prefix": "",
	"translation_editor/search_root": "res://",
	"translation_editor/ignored_folders": "addons"
}|;

TranslationEditor _main_control = null;
Reference _logger = Logger.get_for(this);


void _enter_tree() {
	_logger.debug("Translation editor plugin Enter tree");
	
	EditorInterface editor_interface = get_editor_interface();
	Control base_control = editor_interface.get_base_control();
	
	_main_control = TranslationEditorScene.instance();
	_main_control.configure_for_godot_integration(base_control);
	_main_control.hide();
	editor_interface.get_editor_viewport().add_child(_main_control);
	
	foreach Variant key in _default_settings {
		if not ProjectSettings.has_setting(key) {
			Variant v = _default_settings[key];
			ProjectSettings.set_setting(key, v);
			ProjectSettings.set_initial_value(key, v);
		}
	}
}

void _exit_tree() {
	_logger.debug("Translation editor plugin Exit tree");
	# The main control is not freed when the plugin is disabled
	_main_control.queue_free();
	_main_control = null;
}

bool has_main_screen() {
	return true;
}

String get_plugin_name() {
	return "Loc";
}

Texture get_plugin_icon() {
	return preload("icons/icon_translation_editor.svg");
}

void make_visible(bool visible) {
	_main_control.visible = visible;
}

