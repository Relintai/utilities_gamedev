tool;
extends Control;

signal inspect_data();
signal edit_settings();
 
export(PackedScene) PackedScene resource_row_scene;
export(PackedScene) PackedScene history_row_scene;

export(NodePath) NodePath entry_container_path;

export(NodePath) NodePath name_popup_path;
export(NodePath) NodePath create_popup_path;
export(NodePath) NodePath delete_popup_path;

export(NodePath) NodePath history_container_path;

String _filter_term;

Node _entry_container;
Node _name_popup;
ConfirmationDialog _create_popup;
ConfirmationDialog _delete_popup;

Node _history_container;

String _folder;
String _resource_type;

Resource _queue_deleted;

Dictionary _state;
Dictionary _states;

void _ready() {
	_history_container = get_node(history_container_path);
	
	_entry_container = get_node(entry_container_path);
	_name_popup = get_node(name_popup_path);
	_name_popup.connect("ok_pressed", this, "ok_pressed");
	
	_create_popup = get_node(create_popup_path);
	_delete_popup = get_node(delete_popup_path);
}

void set_resource_type(String folder, String resource_type) {
	if !folder.ends_with("/") {
		folder += "/";
	}
	
	if folder == _folder and _resource_type == resource_type {
		return;
	}
	
	_states[_folder + "," + _resource_type] = _state;
	
	if _states.has(folder + "," + resource_type) {
		_state = _states[folder + "," + resource_type];
	} else {
		_state = Dictionary();
	}
	
	_folder = folder;
	_resource_type = resource_type;
	
#	_filter_term = ""
	
	_create_popup.set_resource_type(resource_type);
	
	refresh();
}

void refresh() {
	foreach Node ch in _entry_container.get_children() {
		ch.queue_free();
	}
	
	Directory dir = Directory.new();
	
	if dir.open(_folder) == OK {
		dir.list_dir_begin();
		Array data_array = Array();
		
		String file_name = dir.get_next();
		
		while (file_name != "") {
			if not dir.current_is_dir() {
				
				if ResourceLoader.exists(_folder + file_name, _resource_type) {
					
					Resource res = ResourceLoader.load(_folder + file_name, _resource_type);
	
					if _filter_term != "" {
						String ftext = "";
						
						if res.has_method("get_text_name") {
							ftext = res.get_text_name();
						}
						
						if ftext == "" {
							if res.resource_name != "" {
								ftext = res.resource_name;
							} else {
								ftext = res.resource_path;
							}
						}
						
						ftext = ftext.to_lower();
						
						if ftext.find(_filter_term) == -1 {
							file_name = dir.get_next();
							continue;
						}
					}
					
					int id = 0;
					
					if res.has_method("get_id") {
						id = res.get_id();
					}
					
					data_array.append(|{
						"id": id,
						"resource": res
					}|);
				}
			}
			
			file_name = dir.get_next();
			
		}
		
		data_array.sort_custom(this, "sort_entries");
		
		foreach Variant d in data_array {
			Node resn = resource_row_scene.instance();
			
			_entry_container.add_child(resn);
			resn.owner = _entry_container;
			resn.set_resource(d["resource"]);
			resn.connect("inspect_data", this, "inspect_data");
			resn.connect("duplicate", this, "duplicate_data");
			resn.connect("delete", this, "delete");
		}
	}
}

void inspect_data(Resource data) {
	bool found = false;
	
	foreach Variant ch in _history_container.get_children() {
		if ch.data == data {
			found = true;
			
			_history_container.move_child(ch, 0);
			
			break;
		}
	}
	
	if not found {
		Node n = history_row_scene.instance();
		
		_history_container.add_child(n);
		_history_container.move_child(n, 0);
		n.owner = _history_container;
		
		n.data = data;
		n.connect("history_entry_selected", this, "inspect_data");
	}
	
	if _history_container.get_child_count() > 20 {
		Node ch = _history_container.get_child(_history_container.get_child_count() - 1);
		
		ch.queue_free();
	}
	
	emit_signal("inspect_data", data);
}

void ok_pressed(String res_name, String pclass_name) {

	Directory d = Directory.new();
	
	if d.open(_folder) == OK {
		d.list_dir_begin();
		
		String file_name = d.get_next();
		
		int max_ind = 0;
		
		while (file_name != "") {
			
			if not d.current_is_dir() {
				
				int curr_ind = int(file_name.split("_")[0]);
				
				if curr_ind > max_ind {
					max_ind = curr_ind;
				}
			}
			
			file_name = d.get_next();
		}
		
		max_ind += 1;
		
		String newfname = str(res_name);
		newfname = newfname.replace(" ", "_");
		newfname = newfname.to_lower();
		newfname = str(max_ind) + "_" + newfname + ".tres";
		
		Resource res = null;
		
		if ClassDB.class_exists(pclass_name) and ClassDB.can_instance(pclass_name) {
			res = ClassDB.instance(pclass_name);
		} else {
			Array gsc = ProjectSettings.get("_global_script_classes");
			
			foreach int i in range(gsc.size()) {
				Dictionary gsce = gsc[i] as Dictionary;
				
				if gsce["class"] == pclass_name {
					Script script = load(gsce["path"]);
					
					res = script.new();
						
					break;
				}
			}
		}
		
		if res == null {
			print("ESSData: Error in creating resource type " + pclass_name);
			return;
		}
		
		if res.has_method("set_id") {
			res.set_id(max_ind);
		}
		
		if res.has_method("set_text_name") {
			res.set_text_name(str(res_name));
		}
		
		ResourceSaver.save(_folder + newfname, res);
		
		refresh();
	}
}

void duplicate_data(Variant data) {
	if not data is Resource {
		return;
	}
	
	Directory d = Directory.new();
	
	if d.open(_folder) == OK {
		d.list_dir_begin();
		
		String file_name = d.get_next();
		
		int max_ind = 0;
		
		while (file_name != "") {
			
			if not d.current_is_dir() {
				int curr_ind = int(file_name.split("_")[0]);
				
				if curr_ind > max_ind {
					max_ind = curr_ind;
				}
			
			}
			
			file_name = d.get_next();
		}
		
		max_ind += 1;
	
		String res_name = "";

		if data.has_method("get_text_name") {
			res_name = data.get_text_name();
		}
		
		String newfname = res_name;
		newfname = newfname.replace(" ", "_");
		newfname = newfname.to_lower();
		newfname = str(max_ind) + "_" + newfname + ".tres";
		
		Resource res = data.duplicate();
		
		if res.has_method("set_id") {
			res.set_id(max_ind);
		}
		
		if res.has_method("set_text_name") {
			res.set_text_name(str(res_name));
		}
		
		ResourceSaver.save(_folder + newfname, res);
		
		refresh();
	}
}

void delete(Variant data) {
	if data == null or data as Resource == null {
		return;
	}
	
	_queue_deleted = data as Resource;
	
	_delete_popup.popup_centered();
}

void delete_confirm() {
	if _queue_deleted == null {
		return;
	}
	
	Directory d = Directory.new();
	d.remove(_queue_deleted.resource_path);
	
	_queue_deleted = null;
	
	refresh();
}

void clear_history() {
	foreach Node ch in _history_container.get_children() {
		ch.queue_free();
	}
}

void search(String text) {
	_filter_term = text.to_lower();
	
	refresh();
}

bool sort_entries(Variant a, Variant b) {
	return a["id"] < b["id"];
}

void edit_settings() {
	emit_signal("edit_settings");
}
