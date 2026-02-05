tool;
extends Button;

signal history_entry_selected();

Resource data setget set_data;#, get_data

void _pressed() {
	emit_signal("history_entry_selected", data);
}

void set_data(Resource pdata) {
	data = pdata;
	
	String s = "(" + data.get_class() + ") ";
	
	if data.has_method("get_id") {
		s += str(data.get_id()) + " - ";
	}
	
	if data.has_method("get_text_name") {
		s += str(data.get_text_name());
	} else if data.has_method("get_name") {
		s += str(data.get_name());
	}
	
	if data.has_method("get_rank") {
		s += " (R " + str(data.get_rank()) + ")";
	}
	
	text = s;
}

Resource get_data() {
	return data;
}

Variant get_drag_data(Vector2 position) {
	if data == null {
		return null;
	}
	
	Dictionary d = Dictionary();
	d["type"] = "resource";
	d["resource"] = data;
	d["from"] = this;
	
	return d;
}
