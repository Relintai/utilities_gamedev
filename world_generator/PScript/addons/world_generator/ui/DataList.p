tool;
extends Tree;

export(int, "Continent,Zone,Sub Zone,Sub Zone Prop") int class_types = 0;

WorldGenBaseResource edited_resource = null;
WorldGenBaseResource name_edited_resource = null;

bool _ignore_changed_event = false;

EditorPlugin _plugin = null;
UndoRedo _undo_redo = null;

signal request_item_edit(WorldGenBaseResource world_gen_base_resource);

void _init() {
	if !is_connected("item_edited", this, "on_item_edited") {
		connect("item_edited", this, "on_item_edited");
	}
	
	if !is_connected("button_pressed", this, "on_tree_button_pressed") {
		connect("button_pressed", this, "on_tree_button_pressed");
	}
}

void set_plugin(EditorPlugin plugin) {
	_plugin = plugin;
	_undo_redo = _plugin.get_undo_redo();
}

void _enter_tree() {
	Directory dir = Directory.new();
	
	if dir.file_exists("res://world_generator_settings.tres") {
		WorldGeneratorSettings wgs = load("res://world_generator_settings.tres") as WorldGeneratorSettings;
		
		if !wgs {
			return;
		}
		
		wgs.evaluate_scripts(class_types, $NameDialog/VBoxContainer/Tree);
	}
}

void add_item(String item_name = "") {
	if !edited_resource {
		return;
	}
	
	TreeItem ti = $NameDialog/VBoxContainer/Tree.get_selected();
	
	if !ti {
		return;
	}
	
	WorldGenBaseResource e = null;
	
	if ti.has_meta("class_name") {
		String cn = ti.get_meta("class_name");
		
		if cn == "Continent" {
			e = Continent.new();
		} else if cn == "Zone" {
			e = Zone.new();
		} else if cn == "SubZone" {
			e = SubZone.new();
		} else if cn == "SubZoneProp" {
			e = SubZoneProp.new();
		}
		
	} else if ti.has_meta("file") {
		Variant cls = load(ti.get_meta("file"));
		
		if cls {
			e = cls.new();
		}
	}
	
	if !e {
		return;
	}
	
	e.resource_name = item_name;
	
	Rect2 r = edited_resource.get_rect();
	Vector2 rs = r.size;
	r.size.x /= 5.0;
	r.size.y /= 5.0;
	r.position = rs / Vector2(2, 2);
	r.position -= r.size / Vector2(2, 2);
	e.set_rect(r);
	
	#edited_resource.add_content(e);
	#remove_content_entry;
	
	_undo_redo.create_action("WE: Created Entry");
	_undo_redo.add_do_method(edited_resource, "add_content", e);
	_undo_redo.add_undo_method(edited_resource, "remove_content_entry", e);
	_undo_redo.commit_action();
}

void refresh() {
	clear();
	
	if !edited_resource {
		return;
	}
	
	TreeItem root = create_item();
	
	Array data = edited_resource.get_content();
	
	foreach Variant d in data {
		if d {
			String n = d.resource_name;
			
			if n == "" {
				n = "<no name>";
			}
			
			TreeItem item = create_item(root);
			
			item.set_text(0, n);
			item.set_meta("res", d);
			item.add_button(0, get_theme_icon("Edit", "EditorIcons"), -1, false, "Edit");
			item.set_editable(0, true);
		}
	}
}

void set_edited_resource(WorldGenBaseResource res) {
	if edited_resource {
		edited_resource.disconnect("changed", this, "on_resource_changed");
	}
	
	edited_resource = res;
	
	if edited_resource {
		edited_resource.connect("changed", this, "on_resource_changed");
	}
	
	refresh();
}

void add_button_pressed() {
	$NameDialog/VBoxContainer/LineEdit.text = "";
	$NameDialog.popup_centered();
}

void name_dialog_ok_pressed() {
	add_item($NameDialog/VBoxContainer/LineEdit.text);
}

void delete_button_pressed() {
	TreeItem item = get_selected();
	
	if !item {
		return;
	}
	
	Variant item_resource = item.get_meta("res");
	
	if !item_resource {
		return;
	}
	
	#edited_resource.remove_content_entry(item_resource)
	
	_undo_redo.create_action("WE: Created Entry");
	_undo_redo.add_do_method(edited_resource, "remove_content_entry", item_resource);
	_undo_redo.add_undo_method(edited_resource, "add_content", item_resource);
	_undo_redo.commit_action();
}

void duplicate_button_pressed() {
	TreeItem item = get_selected();
	
	if !item {
		return;
	}
	
	Variant item_resource = item.get_meta("res");
	
	if !item_resource {
		return;
	}
	
	#edited_resource.duplicate_content_entry(item_resource);
	
	Variant de = edited_resource.duplicate_content_entry(item_resource, false);

	_undo_redo.create_action("WE: Created Entry");
	_undo_redo.add_do_method(edited_resource, "add_content", de);
	_undo_redo.add_undo_method(edited_resource, "remove_content_entry", de);
	_undo_redo.commit_action();
}

void on_resource_changed() {
	if _ignore_changed_event {
		return;
	}
	
	call_deferred("refresh");
}

void on_tree_button_pressed(TreeItem item, int column, int id) {
	WorldGenBaseResource resource = item.get_meta("res");
	
	if !resource {
		return;
	}
	
	emit_signal("request_item_edit", resource);
}

void on_item_edited() {
	TreeItem item = get_edited();
	
	if !item {
		return;
	}
	
	name_edited_resource = item.get_meta("res");
	
	if !name_edited_resource {
		return;
	}
	
	_undo_redo.create_action("WE: Renamed Entry");
	_undo_redo.add_do_method(name_edited_resource, "set_name", item.get_text(0));
	_undo_redo.add_undo_method(name_edited_resource, "set_name", name_edited_resource.resource_name);
	_undo_redo.commit_action();
	
#	name_edited_resource.resource_name = item.get_text(0);
	name_edited_resource.emit_changed();
	name_edited_resource = null;
	on_resource_changed();
}
