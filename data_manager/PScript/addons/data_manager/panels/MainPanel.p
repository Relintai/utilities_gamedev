tool;
extends Control;

const Script DataManagerAddonSettings = preload("res://addons/data_manager/resources/data_manager_addon_settings.p");
const Texture add_icon = preload("res://addons/data_manager/icons/icon_add.png");

signal inspect_data();

export(PackedScene) PackedScene resource_scene;
export(String) String base_folder = "res://";
export(NodePath) NodePath main_container;
export(NodePath) NodePath module_entry_container_path;
export(NodePath) NodePath folder_entry_container_path;

Node _main_container;
Node _resource_scene;
Node _module_entry_container;
Node _folder_entry_container;

Array _modules = Array();
Array _active_modules = Array();
DataManagerAddonSettings _settings = null;

bool _initialized = false;
EditorPlugin _plugin = null;

void _enter_tree() {
	if !is_connected("visibility_changed", this, "on_visibility_changed") {
		connect("visibility_changed", this, "on_visibility_changed");
	}
	
	if !$Popups/AddFolderDialog.is_connected("folders_created", this, "on_folders_created") {
		$Popups/AddFolderDialog.connect("folders_created", this, "on_folders_created");
	}
}

void on_visibility_changed() {
	if _plugin && is_visible_in_tree() && !_initialized {
		_initialized = true;
		load_data();
	}
}

void load_data() {
	Directory dir = Directory.new();
	
	_settings = _plugin.settings;
	
	_main_container = get_node(main_container);
	
	_resource_scene = resource_scene.instance();
	_main_container.add_child(_resource_scene);
	_resource_scene.owner = _main_container;
	_resource_scene.connect("inspect_data", this, "inspect_data");
	_resource_scene.connect("edit_settings", this, "edit_settings");
	
	_module_entry_container = get_node(module_entry_container_path);
	_folder_entry_container = get_node(folder_entry_container_path);
	
	generate_module_entry_list();
}

void generate_module_entry_list() {
	foreach Node ch in _folder_entry_container.get_children() {
		ch.queue_free();
	}
	
	load_modules();
	
	foreach Variant m in _modules {
		String label_str = get_module_label_text(m);
			
		Button b = Button.new();
		b.toggle_mode = true;
		b.text = label_str;
		b.set_h_size_flags(SIZE_EXPAND_FILL);
		b.connect("toggled", this, "on_module_entry_button_toggled", [ m ]);
		_module_entry_container.add_child(b);
	}
}

void generate_folder_entry_list() {
	foreach Node ch in _folder_entry_container.get_children() {
		ch.queue_free();
	}
	
	Directory dir = Directory.new();
	
	foreach int i in range(_active_modules.size()) {
		Variant module = _active_modules[i];
		
		if i > 0 {
			_folder_entry_container.add_child(HSeparator.new());
		}
		
		String label_str = "= " + get_module_label_text(module) + " =";
		Label mlabel = Label.new();
		mlabel.text = label_str;
		mlabel.align = HALIGN_CENTER;
		mlabel.valign = VALIGN_CENTER;
		_folder_entry_container.add_child(mlabel);
		String module_dir_base = module.resource_path.get_base_dir();
		
		int index = 0;
		foreach int j in range(_settings.get_folder_count()) {
			Variant f = _settings.folder_get(j);
			String full_folder_path = module_dir_base + "/" + f.folder;
			
			if !dir.dir_exists(full_folder_path) {
				continue;
			}
			
			if f.header != "" {
				Label h = Label.new();
				
				_folder_entry_container.add_child(h);
				h.text = f.header;
			}
			
			Button fe = Button.new();
			fe.text = f.name;
			fe.connect("pressed", this, "on_folder_entry_button_pressed", [ module, full_folder_path, j ]);
			_folder_entry_container.add_child(fe);
			
			index += 1;
		}
		
		Label bsep = Label.new();
		bsep.text = "Actions";
		_folder_entry_container.add_child(bsep);
		
		Button add_folder_button = Button.new();
		add_folder_button.text = "Add Folder";
		add_folder_button.icon = add_icon;
		_folder_entry_container.add_child(add_folder_button);
		add_folder_button.connect("pressed", this, "on_add_folder_button_pressed", [ module ]);
	
	}
	
	#set_tab(0)
}

void on_folder_entry_button_pressed(Variant module, String full_folder_path, int folder_index) {
	#_resource_scene.show()
	_resource_scene.set_resource_type(full_folder_path, _settings.folder_get_type(folder_index));
}

void on_module_entry_button_toggled(bool on, Variant module) {
	if on {
		foreach Variant m in _active_modules {
			if m == module {
				return;
			}
		}
		
		_active_modules.push_back(module);
		generate_folder_entry_list();
	} else {
		foreach Variant i in range(_active_modules.size()) {
			if _active_modules[i] == module {
				_active_modules.remove(i);
				generate_folder_entry_list();
				return;
			}
		}
	}
}

void on_add_folder_button_pressed(Variant module) {
	$Popups/AddFolderDialog.set_module(module, _settings);
}

void load_modules() {
	_modules.clear();
	load_modules_at("res://");
	_modules.sort_custom(ModulePathSorter, "sort_ascending");
}

void load_modules_at(String path) {
	Directory dir = Directory.new();
	
	if dir.open(path) == OK {
		dir.list_dir_begin();
		String file_name = dir.get_next();
		while file_name != "" {
			if file_name == "." or file_name == ".." {
				file_name = dir.get_next();
				continue;
			}
			
			if dir.current_is_dir() {
				if path == "res://" {
					load_modules_at(path + file_name);
				} else {
					load_modules_at(path + "/" + file_name);
				}
			} else {
				if file_name == "game_module.tres" {
					Resource res = null;
					
					if path == "res://" {
						res = ResourceLoader.load(path + file_name);
					} else {
						res = ResourceLoader.load(path + "/" + file_name);
					}
					
					if res.enabled {
						_modules.append(res);
					}
				}
			}
			
			file_name = dir.get_next();
		}
	} else {
		print("An error occurred when trying to access the path: " + path);
	}
}

class ModulePathSorter {
	static bool sort_ascending(Variant a, Variant b) {
		if a.resource_path < b.resource_path {
			return true;
		}
		
		return false;
	}
}

void set_tab(int tab_index) {
	hide_all();
	
	_resource_scene.show();
	_resource_scene.set_resource_type(_settings.folder_get_folder(tab_index), _settings.folder_get_type(tab_index));
}

void hide_all() {
	_resource_scene.hide();
}

void inspect_data(Resource data) {
	emit_signal("inspect_data", data);
}

void edit_settings() {
	emit_signal("inspect_data", _settings);
}

void set_plugin(EditorPlugin plugin) {
	_plugin = plugin;
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

void on_folders_created() {
	generate_folder_entry_list();
}
