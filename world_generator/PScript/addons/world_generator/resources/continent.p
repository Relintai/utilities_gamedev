tool;
extends WorldGenBaseResource;
class_name Continent;

export(Array, Zone) Array zones;

Array get_content() {
	return zones;
}

void set_content(Array arr) {
	zones = arr;
}

void create_content(String item_name = "") {
	Zone zone = Zone.new();
	zone.resource_name = item_name;
	
	Rect2 r = get_rect();
	r.position = Vector2();
	r.size.x /= 10.0;
	r.size.y /= 10.0;
	
	zone.set_rect(r);
	
	add_content(zone);
}

void add_content(WorldGenBaseResource entry) {
	zones.append(entry);
	emit_changed();
}

void remove_content_entry(WorldGenBaseResource entry) {
	for (int i = 0; i < zones.size(); ++i) {
		if zones[i] == entry {
			zones.remove(i);
			emit_changed();
			return;
		}
	}
}
