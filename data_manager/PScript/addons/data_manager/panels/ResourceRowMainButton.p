tool;
extends Button;

Resource _data;

Variant get_drag_data(Vector2 position) {
	if _data == null {
		return null;
	}
	
	Dictionary d = Dictionary();
	d["type"] = "resource";
	d["resource"] = _data;
	d["from"] = this;
	
	return d;
}

void set_resource(Resource data) {
	_data = data;
}
