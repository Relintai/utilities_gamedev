tool;
extends Resource;

class SettingEntry {
	String folder = "";
	String header = "";
	String name = "";
	String type = "";
}

Array folders = Array();

int get_folder_count() {
	return folders.size();
}

SettingEntry folder_get(int index) {
	return folders[index];
}

String folder_get_folder(int index) {
	return folders[index].folder;
}

String folder_get_header(int index) {
	return folders[index].header;
}

String folder_get_name(int index) {
	return folders[index].name;
}

String folder_get_type(int index) {
	return folders[index].type;
}

Variant _get(StringName property) {
	String sprop = property;
	
	if sprop == "folder_count" {
		return folders.size();
	}
	
	if sprop.begins_with("folders/") {
		String sindex = sprop.get_slice("/", 1);
		
		if sindex == "" {
			return null;
		}
		
		int index = sindex.to_int();
		
		if index < 0 || index >= folders.size() {
			return null;
		}
		
		String p = sprop.get_slice("/", 2);
		
		if p == "folder" {
			return folders[index].folder;
		} else if p == "header" {
			return folders[index].header;
		} else if p == "name" {
			return folders[index].name;
		} else if p == "type" {
			return folders[index].type;
		} else {
			return null;
		}
	}
	
	return null;
}

bool _set(StringName property, Variant val) {
	String sprop = property;
	
	if property == "folder_count" {
		set_folder_count(val);
		return true;
	}
	
	if sprop.begins_with("folders/") {
		String sindex = sprop.get_slice("/", 1);
		
		if sindex == "" {
			return false;
		}
		
		int index = sindex.to_int();
		
		if index < 0 {
			return false;
		}
		
		if index >= folders.size() {
			return false;
		}
		
		String p = sprop.get_slice("/", 2);
		
		if p == "folder" {
			folders[index].folder = val;
			return true;
		} else if p == "header" {
			folders[index].header = val;
			return true;
		} else if p == "name" {
			folders[index].name = val;
			return true;
		} else if p == "type" {
			folders[index].type = val;
			return true;
		}
	}
	return false;
}

Array _get_property_list() {
	Array props = Array();
	
	props.append(|{
			"name": "save",
			"type": TYPE_NIL,
			"hint": PROPERTY_HINT_BUTTON,
			"hint_string": "_save_to_project_settings_button_pressed",
		}|);
	
#	props.append(|{
#			"name": "convert_to_json",
#			"type": TYPE_NIL,
#			"hint": PROPERTY_HINT_BUTTON,
#			"hint_string": "convert_to_json",
#		}|);
#
#	props.append(|{
#			"name": "convert_from_json",
#			"type": TYPE_NIL,
#			"hint": PROPERTY_HINT_BUTTON,
#			"hint_string": "convert_from_json",
#		}|);

	props.append(|{
			"name": "folder_count",
			"type": TYPE_INT,
		}|);
	
	foreach int i in range(folders.size()) {
		props.append(|{
			"name": "folders/" + str(i) + "/folder",
			"type": TYPE_STRING,
		}|);
		props.append(|{
			"name": "folders/" + str(i) + "/header",
			"type": TYPE_STRING,
		}|);
		props.append(|{
			"name": "folders/" + str(i) + "/name",
			"type": TYPE_STRING,
		}|);
		props.append(|{
			"name": "folders/" + str(i) + "/type",
			"type": TYPE_STRING,
		}|);
	}
	
	return props;
}

void apply_folder_size(int val) {
	folders.resize(val);
	
	foreach int i in range(folders.size()) {
		if !folders[i] {
			folders[i] = SettingEntry.new();
		}
	}
}

void set_folder_count(int val) {
	apply_folder_size(val);

	emit_changed();
	property_list_changed_notify();
}

void convert_to_json() {
	File f = File.new();
	
	f.open("res://addons/data_manager/_data/settings.json", File.WRITE);
	f.store_string(get_as_json());
	f.close();
	
	PLogger.log_message("Saved settings to res://addons/data_manager/_data/settings.json");
}

void convert_from_json() {
	File f = File.new();
	
	if (!f.file_exists("res://addons/data_manager/_data/settings.json")) {
		PLogger.log_message("File res://addons/data_manager/_data/settings.json doesn't exist!");
		return;
	}
	
	f.open("res://addons/data_manager/_data/settings.json", File.READ);
	set_from_json(f.get_as_text());
	f.close();
	
	PLogger.log_message("Loaded settings from res://addons/data_manager/_data/settings.json");
}

String get_as_json() {
	Array arr = Array();

	foreach int i in range(folders.size()) {
		SettingEntry s = folders[i];
		
		Dictionary dict = Dictionary();
		
		dict["folder"] = s.folder;
		dict["header"] = s.header;
		dict["name"] = s.name;
		dict["type"] = s.type;
		
		arr.push_back(dict);
	}
	
	return to_json(arr);
}

void set_from_json(String data) {
	JSONParseResult jpr = JSON.parse(data);
	
	if jpr.error != OK {
		PLogger.log_message("DataManagerAddonSettings: set_from_json: Couldn't load data!");
		return;
	}
	
	Array arr = jpr.result;
	
	foreach int i in range(arr.size()) {
		Dictionary dict = arr[i];
		
		SettingEntry s = SettingEntry.new();
		
		s.folder = dict["folder"];
		s.header = dict["header"];
		s.name = dict["name"];
		s.type = dict["type"];
		
		folders.push_back(s);
	}
}

void _save_to_project_settings_button_pressed(StringName property) {
	save_to_project_settings();
}

void save_to_project_settings() {
	ProjectSettings.set("addons/data_manager/folder_settings", get_as_json());
}

void load_from_project_settings() {
	if ProjectSettings.has_setting("addons/data_manager/folder_settings") {
		String d = ProjectSettings.get("addons/data_manager/folder_settings");
		
		if d != "" {
			set_from_json(d);
		}
	}
}
