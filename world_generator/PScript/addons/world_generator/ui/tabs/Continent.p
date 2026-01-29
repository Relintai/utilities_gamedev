tool;
extends HBoxContainer;

WorldGenWorld edited_world = null;
Continent edited_continent = null;

signal request_item_edit(Continent continent, WorldGenBaseResource world_gen_base_resource);

void _ready() {
	OptionButton option_button = $HSplitContainer/VBoxContainer/OptionButton;
	option_button.connect("item_selected", this, "on_item_selected");
	
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

void refresh_continent() {
	$HSplitContainer/VBoxContainer/HBoxContainer2/ResourcePropertyList.edit_resource(edited_continent);
	$HSplitContainer/VBoxContainer/HBoxContainer2/VBoxContainer/DataList.set_edited_resource(edited_continent);
	$HSplitContainer/RectEditor.set_edited_resource(edited_continent);

#	if !edited_continent:
#		return
}

void refresh() {
	OptionButton option_button = $HSplitContainer/VBoxContainer/OptionButton;
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
	
	refresh_continent();
}

void set_wgworld(WorldGenWorld wgw) {
	edited_world = wgw;
	
	refresh();
}

void switch_to(WorldGenBaseResource resource) {
	OptionButton option_button = $HSplitContainer/VBoxContainer/OptionButton;
	
	for (int i = 0; i < option_button.get_item_count(); ++i) {
		Continent continent = option_button.get_item_metadata(i);
		
		if (continent == resource) {
			option_button.select(i);
			set_continent(continent);
			return;
		}
	}
}

void set_continent(Continent continent) {
	edited_continent = continent;
	
	refresh_continent();
}

void on_item_selected(int idx) {
	OptionButton option_button = $HSplitContainer/VBoxContainer/OptionButton;
	
	set_continent(option_button.get_item_metadata(idx));
}

void on_request_item_edit(WorldGenBaseResource resource) {
	emit_signal("request_item_edit", edited_continent, resource);
}

void _on_Continent_visibility_changed() {
	if visible {
		refresh();
	}
}
