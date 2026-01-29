tool;
extends HBoxContainer;

WorldGenWorld edited_world = null;
Continent edited_continent = null;
Zone edited_zone = null;
SubZone edited_sub_zone = null;

signal request_item_edit(Continent continent, Zone zone, SubZone subzone, SubZoneProp subzone_prop);

void _ready() {
	OptionButton coption_button = $HSplitContainer/VBoxContainer/ContinentOptionButton;
	coption_button.connect("item_selected", this, "on_continent_item_selected");
	
	OptionButton zoption_button = $HSplitContainer/VBoxContainer/ZoneOptionButton;
	zoption_button.connect("item_selected", this, "on_zone_item_selected");
	
	OptionButton szoption_button = $HSplitContainer/VBoxContainer/SubZoneOptionButton;
	szoption_button.connect("item_selected", this, "on_sub_zone_item_selected");
	
	Control dl = get_node("HSplitContainer/VBoxContainer/HBoxContainer2/VBoxContainer/DataList");
	if !dl.is_connected("request_item_edit", this, "on_request_item_edit") {
		dl.connect("request_item_edit", this, "on_request_item_edit");
	}
}

void set_plugin(EditorPlugin plugin) {
	$HSplitContainer/VBoxContainer/HBoxContainer2/ResourcePropertyList.set_plugin(plugin);
	$HSplitContainer/VBoxContainer/HBoxContainer2/VBoxContainer/DataList.set_plugin(plugin);
	$HSplitContainer/RectEditor.set_plugin(plugin);
}

void refresh() {
	OptionButton option_button = $HSplitContainer/VBoxContainer/ContinentOptionButton;
	option_button.clear();
	edited_continent = null;
	edited_zone = null;

	if !edited_world {
		return;
	}
	
	Array content = edited_world.get_content();
	
	foreach Variant c in content {
		if c {
			option_button.add_item(c.resource_name);
			option_button.set_item_metadata(option_button.get_item_count() - 1, c);
			
			if !edited_continent {
				edited_continent = c;
			}
		}
	}
	continent_changed();
}

void continent_changed() {
	OptionButton option_button = $HSplitContainer/VBoxContainer/ZoneOptionButton;
	option_button.clear();
	edited_zone = null;

	if !edited_continent {
		return;
	}
	
	Array content = edited_continent.get_content();
	
	foreach Variant c in content {
		if c {
			option_button.add_item(c.resource_name);
			option_button.set_item_metadata(option_button.get_item_count() - 1, c);
			
			if !edited_zone {
				edited_zone = c;
			}
		}
	}
	
	zone_changed();
}

void zone_changed() {
	OptionButton option_button = $HSplitContainer/VBoxContainer/SubZoneOptionButton;
	option_button.clear();
	edited_sub_zone = null;

	if !edited_zone {
		return;
	}
	
	Array content = edited_zone.get_content();
	
	foreach Variant c in content {
		if c {
			option_button.add_item(c.resource_name);
			option_button.set_item_metadata(option_button.get_item_count() - 1, c);
			
			if !edited_sub_zone {
				edited_sub_zone = c;
			}
		}
	}
	
	sub_zone_changed();
}

void sub_zone_changed() {
	$HSplitContainer/VBoxContainer/HBoxContainer2/ResourcePropertyList.edit_resource(edited_sub_zone);
	$HSplitContainer/VBoxContainer/HBoxContainer2/VBoxContainer/DataList.set_edited_resource(edited_sub_zone);
	$HSplitContainer/RectEditor.set_edited_resource(edited_sub_zone);
}

void set_continent(Continent continent) {
	edited_continent = continent;
	edited_zone = null;
	
	continent_changed();
}

void set_zone(Zone zone) {
	edited_zone = zone;
	
	zone_changed();
}

void set_sub_zone(SubZone sub_zone) {
	edited_sub_zone = sub_zone;
	
	sub_zone_changed();
}

void set_wgworld(WorldGenWorld wgw) {
	edited_world = wgw;
	edited_continent = null;
	edited_zone = null;
	
	refresh();
}

void switch_to(WorldGenBaseResource continent, WorldGenBaseResource zone, WorldGenBaseResource subzone) {
	OptionButton contob = $HSplitContainer/VBoxContainer/ContinentOptionButton;
	
	for (int i = 0; i < contob.get_item_count(); ++i) {
		Continent ccont = contob.get_item_metadata(i);
		
		if (ccont == continent) {
			contob.select(i);
			set_continent(continent);
			break;
		}
	}
	
	OptionButton zoneob = $HSplitContainer/VBoxContainer/ZoneOptionButton;
			
	for (int i = 0; i < zoneob.get_item_count(); ++i) {
		Zone czone = zoneob.get_item_metadata(i);
		
		if (czone == zone) {
			zoneob.select(i);
			set_zone(zone);
			break;
		}
	}
	
	OptionButton subzoneob = $HSplitContainer/VBoxContainer/SubZoneOptionButton;
			
	for (int i = 0; i < subzoneob.get_item_count(); ++i) {
		SubZone cszone = subzoneob.get_item_metadata(i);
		
		if (cszone == subzone) {
			subzoneob.select(i);
			set_sub_zone(subzone);
			return;
		}
	}
}

void on_continent_item_selected(int idx) {
	OptionButton option_button = $HSplitContainer/VBoxContainer/ContinentOptionButton;
	
	set_continent(option_button.get_item_metadata(idx));
}

void on_zone_item_selected(int idx) {
	OptionButton option_button = $HSplitContainer/VBoxContainer/ZoneOptionButton;
	
	set_zone(option_button.get_item_metadata(idx));
}

void on_sub_zone_item_selected(int idx) {
	OptionButton option_button = $HSplitContainer/VBoxContainer/SubZoneOptionButton;
	
	set_sub_zone(option_button.get_item_metadata(idx));
}

void on_request_item_edit(WorldGenBaseResource resource) {
	emit_signal("request_item_edit", edited_continent, edited_zone, edited_sub_zone, resource);
}

void _on_SubZone_visibility_changed() {
	if visible {
		refresh();
	}
}
