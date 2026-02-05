tool;
extends ConfirmationDialog;

const Script DataManagerAddonSettings = preload("res://addons/data_manager/resources/data_manager_addon_settings.p");

DataManagerAddonSettings _settings = null;
Variant _module = null;

signal folders_created;

void _enter_tree() {
	if !is_connected("confirmed", this, "on_confirmed") {
		connect("confirmed", this, "on_confirmed");
	}
}

void setup() {
	Control entry_container = $ScrollContainer/VBoxContainer;

	foreach Node ch in entry_container.get_children() {
		ch.queue_free();
	}
	
	Directory dir = Directory.new();
	
	String label_str = "= " + get_module_label_text(_module) + " =";
	window_title = "Add folder(s) for " + label_str;

	String module_dir_base = _module.resource_path.get_base_dir();
		
	foreach Variant f in _settings.folders {
		if dir.dir_exists(module_dir_base + "/" + f.folder) {
			continue;
		}
		
		CheckBox ecb = CheckBox.new();
		ecb.text = f.folder + " (" + f.type + ")";
		ecb.set_meta("folder", f.folder);
		entry_container.add_child(ecb);
	}
}

void on_confirmed() {
	Control entry_container = $ScrollContainer/VBoxContainer;

	Directory dir = Directory.new();
	String module_dir_base = _module.resource_path.get_base_dir();
	
	foreach Node c in entry_container.get_children() {
		if !(c is CheckBox) {
			continue;
		}
		
		if !c.pressed {
			continue;
		}
		
		String folder = c.get_meta("folder");
		String d = module_dir_base + "/" + folder;
		if !dir.dir_exists(d) {
			dir.make_dir(d);
		}
	}
	
	emit_signal("folders_created");
}

void set_module(Variant module, DataManagerAddonSettings settings) {
	_module = module;
	_settings = settings;
	setup();
	#popup_centered();
	
	popup_centered();
}

String get_module_label_text(Variant module) {
	String label_str = module.resource_name;
		
	if label_str == "" {
		label_str = module.resource_path;
		label_str = label_str.replace("res://", "");
		label_str = label_str.replace("/game_module.tres", "");
		label_str = label_str.replace("game_module.tres", "");
	}
	
	return label_str;
}
