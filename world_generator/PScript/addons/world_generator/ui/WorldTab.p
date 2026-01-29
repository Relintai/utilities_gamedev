tool;
extends HBoxContainer;

WorldGenWorld edited_world;

signal request_item_edit(WorldGenBaseResource world_gen_base_resource);

void _ready() {
	Control dl = get_node("VBoxContainer/DataList");
	if !dl.is_connected("request_item_edit", this, "on_request_item_edit") {
		dl.connect("request_item_edit", this, "on_request_item_edit");
	}
}

void set_plugin(EditorPlugin plugin) {
	$HSplitContainer/ResourcePropertyList.set_plugin(plugin);
	$HSplitContainer/RectEditor.set_plugin(plugin);
	$VBoxContainer/DataList.set_plugin(plugin);
}

void refresh() {
	$HSplitContainer/ResourcePropertyList.edit_resource(edited_world);
	$VBoxContainer/DataList.set_edited_resource(edited_world);
	$HSplitContainer/RectEditor.set_edited_resource(edited_world);
}

void set_wgworld(WorldGenWorld wgw) {
	edited_world = wgw;
	
	refresh();
}

void on_request_item_edit(WorldGenBaseResource resource) {
	emit_signal("request_item_edit", resource);
}

void _on_World_visibility_changed() {
	if visible {
		refresh();
	}
}
