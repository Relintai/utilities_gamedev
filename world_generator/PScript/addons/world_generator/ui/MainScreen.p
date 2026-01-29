tool;
extends PanelContainer;

Variant edited_world;

void _ready() {
	Control world = get_node("TabContainer/World");
	if !world.is_connected("request_item_edit", this, "on_world_request_item_edit") {
		world.connect("request_item_edit", this, "on_world_request_item_edit");
	}
	
	Control continent = get_node("TabContainer/Continent");
	if !continent.is_connected("request_item_edit", this, "on_continent_request_item_edit") {
		continent.connect("request_item_edit", this, "on_continent_request_item_edit");
	}
	
	Control zone = get_node("TabContainer/Zone");
	if !zone.is_connected("request_item_edit", this, "on_zone_request_item_edit") {
		zone.connect("request_item_edit", this, "on_zone_request_item_edit");
	}
	
	Control subzone = get_node("TabContainer/SubZone");
	if !subzone.is_connected("request_item_edit", this, "on_subzone_request_item_edit") {
		subzone.connect("request_item_edit", this, "on_subzone_request_item_edit");
	}
}

void set_plugin(EditorPlugin plugin) {
	$TabContainer/World.set_plugin(plugin);
	$TabContainer/Continent.set_plugin(plugin);
	$TabContainer/Zone.set_plugin(plugin);
	$TabContainer/SubZone.set_plugin(plugin);
	$TabContainer/SubZoneProp.set_plugin(plugin);
}

void refresh() {
	$TabContainer/World.set_wgworld(edited_world);
	$TabContainer/Continent.set_wgworld(edited_world);
	$TabContainer/Zone.set_wgworld(edited_world);
	$TabContainer/SubZone.set_wgworld(edited_world);
	$TabContainer/SubZoneProp.set_wgworld(edited_world);
}

void set_wgworld(WorldGenWorld wgw) {
	edited_world = wgw;
	
	refresh();
}

void on_world_request_item_edit(WorldGenBaseResource resource) {
	Control cont = get_node("TabContainer/Continent");
	
	TabContainer tc = get_node("TabContainer");
	tc.current_tab = cont.get_position_in_parent();
	
	cont.switch_to(resource);
}

void on_continent_request_item_edit(WorldGenBaseResource continent, WorldGenBaseResource resource) {
	Control zone = get_node("TabContainer/Zone");
	
	TabContainer tc = get_node("TabContainer");
	tc.current_tab = zone.get_position_in_parent();

	zone.switch_to(continent, resource);
}

void on_zone_request_item_edit(WorldGenBaseResource continent, WorldGenBaseResource zone, WorldGenBaseResource subzone) {
	Control sz = get_node("TabContainer/SubZone");
	
	TabContainer tc = get_node("TabContainer");
	tc.current_tab = sz.get_position_in_parent();

	sz.switch_to(continent, zone, subzone);
}

void on_subzone_request_item_edit(WorldGenBaseResource continent, WorldGenBaseResource zone, WorldGenBaseResource subzone, WorldGenBaseResource subzone_prop) {
	Control sz = get_node("TabContainer/SubZoneProp");
	
	TabContainer tc = get_node("TabContainer");
	tc.current_tab = sz.get_position_in_parent();

	sz.switch_to(continent, zone, subzone, subzone_prop);
}
