tool;
extends WorldGenBaseResource;
class_name Zone;

export(Array, SubZone) Array subzones;

Array get_content() {
	return subzones;
}

void set_content(Array arr) {
	subzones = arr;
}

void create_content(String item_name = "") {
	SubZone subzone = SubZone.new();
	subzone.resource_name = item_name;
	
	Rect2 r = get_rect();
	r.position = Vector2();
	r.size.x /= 10.0;
	r.size.y /= 10.0;
	
	subzone.set_rect(r);
	
	add_content(subzone);
}

void add_content(WorldGenBaseResource entry) {
	subzones.append(entry);
	emit_changed();
}

void remove_content_entry(WorldGenBaseResource entry) {
	for (int i = 0; i < subzones.size(); ++i) {
		if subzones[i] == entry {
			subzones.remove(i);
			emit_changed();
			return;
		}
	}
}
