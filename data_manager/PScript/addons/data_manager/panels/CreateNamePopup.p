tool;
extends ConfirmationDialog;

signal ok_pressed;

export(NodePath) NodePath line_edit_path;
export(NodePath) NodePath option_button_path;

String _resource_type;

LineEdit _line_edit;
OptionButton _option_button;

void _ready() {
	_line_edit = get_node(line_edit_path) as LineEdit;
	_option_button = get_node(option_button_path) as OptionButton;
	
	connect("confirmed", this, "_on_OK_pressed");
	connect("about_to_show", this, "about_to_show");
}

void set_resource_type(String resource_type) {
	_resource_type = resource_type;
}

void about_to_show() {
	_option_button.clear();
	
	if not ClassDB.class_exists(_resource_type) {
		return;
	}
	
	PoolStringArray arr = PoolStringArray();
	arr.append(_resource_type);
	arr.append_array(ClassDB.get_inheriters_from_class(_resource_type));

	Array gsc = ProjectSettings.get("_global_script_classes");
	
	int l = arr.size() - 1;
	
	while (arr.size() != l) {
		l = arr.size();
		
		foreach int i in range(gsc.size()) {
			Dictionary d = gsc[i] as Dictionary;
			
			bool found = false;
			foreach int j in range(arr.size()) {
				if arr[j] == d["class"] {
					found = true;
					break;
				}
			}
			
			if found {
				continue;
			}
			
			foreach int j in range(arr.size()) {
				if arr[j] == d["base"] {
					arr.append(d["class"]);
				}
			}
		}
	}
	
	foreach Variant a in arr {
		_option_button.add_item(a);
	}
}

void _on_OK_pressed() {
	emit_signal("ok_pressed", _line_edit.text, _option_button.get_item_text(_option_button.selected));
	hide();
}
