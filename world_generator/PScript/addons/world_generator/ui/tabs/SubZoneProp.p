tool;
extends HBoxContainer;

WorldGenWorld edited_world = null;
Continent edited_continent = null;
Zone edited_zone = null;
SubZone edited_sub_zone = null;
SubZoneProp edited_sub_zone_prop = null;

void _ready() {
	OptionButton coption_button = $VBoxContainer/ContinentOptionButton;
	coption_button.connect("item_selected", this, "on_continent_item_selected");
	
	OptionButton zoption_button = $VBoxContainer/ZoneOptionButton;
	zoption_button.connect("item_selected", this, "on_zone_item_selected");
	
	OptionButton szoption_button = $VBoxContainer/SubZoneOptionButton;
	szoption_button.connect("item_selected", this, "on_sub_zone_item_selected");
	
	OptionButton szpoption_button = $VBoxContainer/SubZonePropOptionButton;
	szpoption_button.connect("item_selected", this, "on_sub_zone_prop_item_selected");
}

void set_plugin(EditorPlugin plugin) {
	$VBoxContainer/HBoxContainer2/ResourcePropertyList.set_plugin(plugin);
}

void continent_changed() {
	OptionButton option_button = $VBoxContainer/ZoneOptionButton;
	option_button.clear();
	edited_zone = null;
	edited_sub_zone = null;

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
	OptionButton option_button = $VBoxContainer/SubZoneOptionButton;
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
	OptionButton option_button = $VBoxContainer/SubZonePropOptionButton;
	option_button.clear();
	edited_sub_zone_prop = null;

	if !edited_sub_zone {
		return;
	}
	
	Array content = edited_sub_zone.get_content();
	
	foreach Variant c in content {
		if c {
			option_button.add_item(c.resource_name);
			option_button.set_item_metadata(option_button.get_item_count() - 1, c);
			
			if !edited_sub_zone_prop {
				edited_sub_zone_prop = c;
			}
		}
	}
	
	sub_zone_prop_changed();
}

void sub_zone_prop_changed() {
	$VBoxContainer/HBoxContainer2/ResourcePropertyList.edit_resource(edited_sub_zone_prop);
}

void refresh() {
	OptionButton option_button = $VBoxContainer/ContinentOptionButton;
	option_button.clear();

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

void set_wgworld(WorldGenWorld wgw) {
	edited_world = wgw;
	edited_continent = null;
	edited_zone = null;
	edited_sub_zone = null;
	edited_sub_zone_prop = null;
	
	refresh();
}

void set_continent(Continent continent) {
	edited_continent = continent;
	edited_zone = null;
	edited_sub_zone = null;
	edited_sub_zone_prop = null;
	
	continent_changed();
}

void set_zone(Zone zone) {
	edited_zone = zone;
	edited_sub_zone = null;
	edited_sub_zone_prop = null;
	
	zone_changed();
}

void set_sub_zone(SubZone sub_zone ) {
	edited_sub_zone = sub_zone;
	edited_sub_zone_prop = null;
	
	sub_zone_changed();
}
 
void set_sub_zone_prop(SubZoneProp sub_zone_prop) {
	edited_sub_zone_prop = sub_zone_prop;
	
	sub_zone_prop_changed();
}

void switch_to(WorldGenBaseResource continent, WorldGenBaseResource zone, WorldGenBaseResource subzone, WorldGenBaseResource subzone_prop) {
	OptionButton contob = $VBoxContainer/ContinentOptionButton;
	
	for (int i = 0; i < contob.get_item_count(); ++i) {
		Continent ccont = contob.get_item_metadata(i);
		
		if (ccont == continent) {
			contob.select(i);
			set_continent(continent);
			break;
		}
	}
	
	OptionButton zoneob = $VBoxContainer/ZoneOptionButton;
	
	for (int i = 0; i < zoneob.get_item_count(); ++i) {
		Zone czone = zoneob.get_item_metadata(i);
		
		if (czone == zone) {
			zoneob.select(i);
			set_zone(zone);
			break;
		}
	}
	
	OptionButton subzoneob = $VBoxContainer/SubZoneOptionButton;
	
	for (int i = 0; i < subzoneob.get_item_count(); ++i) {
		SubZone cszone = subzoneob.get_item_metadata(i);
		
		if (cszone == subzone) {
			subzoneob.select(i);
			set_sub_zone(subzone);
			break;
		}
	}
	
	OptionButton subzonepropob = $VBoxContainer/SubZonePropOptionButton;
	
	for (int i = 0; i < subzonepropob.get_item_count(); ++i) {
		SubZoneProp cszoneprop = subzonepropob.get_item_metadata(i);
		
		if (cszoneprop == subzone_prop) {
			subzonepropob.select(i);
			set_sub_zone_prop(subzone_prop);
			return;
		}
	}
}

void on_continent_item_selected(int idx) {
	OptionButton option_button = $VBoxContainer/ContinentOptionButton;
	
	set_continent(option_button.get_item_metadata(idx));
}

void on_zone_item_selected(int idx) {
	OptionButton option_button = $VBoxContainer/ZoneOptionButton;
	
	set_zone(option_button.get_item_metadata(idx));
}

void on_sub_zone_item_selected(int idx) {
	OptionButton option_button = $VBoxContainer/SubZoneOptionButton;
	
	set_sub_zone(option_button.get_item_metadata(idx));
}

void on_sub_zone_prop_item_selected(int idx) {
	OptionButton option_button = $VBoxContainer/SubZonePropOptionButton;
	
	set_sub_zone_prop(option_button.get_item_metadata(idx));
}
