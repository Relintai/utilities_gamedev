tool;
extends WorldGenBaseResource;
class_name SubZone;

export(Array, SubZoneProp) Array subzone_props;

Array get_content() {
	return subzone_props;
}

void set_content(Array arr) {
	subzone_props = arr;
}

void create_content(String item_name = "") {
	SubZoneProp subzone_prop = SubZoneProp.new();
	subzone_prop.resource_name = item_name;
	
	Rect2 r = get_rect();
	r.position = Vector2();
	r.size.x /= 10.0;
	r.size.y /= 10.0;
	
	subzone_prop.set_rect(r);
	
	add_content(subzone_prop);
}

void add_content(WorldGenBaseResource entry) {
	subzone_props.append(entry);
	emit_changed();
}

void remove_content_entry(WorldGenBaseResource entry) {
	for (int i = 0; i < subzone_props.size(); ++i) {
		if subzone_props[i] == entry {
			subzone_props.remove(i);
			emit_changed();
			return;
		}
	}
}
