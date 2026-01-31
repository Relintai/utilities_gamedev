tool;
extends EditorPlugin;

HBoxContainer controls = null;

MeshDataResource array_mesh_to_mdr(ArrayMesh mesh) {
	MeshDataResource mdr = MeshDataResource.new();
	
	if mesh.get_surface_count() > 0 {
		mdr.array = mesh.surface_get_arrays(0);
	}
	
	return mdr;
}

void convert_to_mdi() {
	Array md = get_current_root_mesh();
		
	if md.size() == 0 {
		return;
	}
	
	MeshInstance cs = md[0];
	ArrayMesh mesh = md[1];
	
	Node n = Node.new();
	n.name = "NewNodes";
	cs.add_child(n);
	n.owner = get_editor_interface().get_edited_scene_root();
	
	MeshDataInstance mdi = MeshDataInstance.new();
	mdi.transform = cs.transform;
	mdi.mesh_data = array_mesh_to_mdr(mesh);
	n.add_child(mdi);
	mdi.owner = get_editor_interface().get_edited_scene_root();
}

void merge_to_new_mi() {
	# Meshes need to be transformed, so this is disabled, it's not needed, it's probably better
	# to just use more than one MDIs
	Array md = get_current_root_mesh();
		
	if md.size() == 0 {
		return;
	}
	
	MeshInstance cs = md[0];
	ArrayMesh mesh = md[1];
	
	Node n = Node.new();
	n.name = "NewNodes";
	
	process_node(cs, n);
	
	cs.add_child(n);
	n.owner = get_editor_interface().get_edited_scene_root();
}

void process_node(Node current_node, Node new_root) {
	
	if current_node is MeshInstance {
	
		MeshInstance cs = current_node as MeshInstance;
		
		bool merged = false;
		foreach Variant c in new_root {
			MeshInstance nc = c;
			Mesh m = nc.mesh;
			
			if m && nc.merge_meshes([m], true) {
				merged = true;
				break;
			}
		}
		
		if !merged {
			MeshInstance mi = cs.duplicate();
			new_root.add_child(mi);
			mi.global_transform = cs.global_transform;
			mi.owner = get_editor_interface().get_edited_scene_root();
		}
	}
}

Array get_current_root_mesh() {
	Array sn = get_editor_interface().get_selection().get_selected_nodes();
	
	if sn.size() != 1 {
		return [];
	}
	
	if !(sn[0] is MeshInstance) {
		return [];
	}
	
	MeshInstance cs = sn[0] as MeshInstance;
	
	ArrayMesh mesh = cs.mesh;
	
	return [ cs, mesh ];
}

void _enter_tree() {
	# We need to do this, because we don't want to take over CSG's editor plugin
	get_editor_interface().get_selection().connect(@"selection_changed", this, @"_on_selection_changed");
	
	Control base_control = get_editor_interface().get_base_control();
	
	controls = HBoxContainer.new();
	
	controls.add_child(VSeparator.new());
	MenuButton button = MenuButton.new();
	controls.add_child(button);
	button.icon = base_control.get_theme_icon(@"MeshDataInstance", @"EditorIcons");
	button.hint_tooltip = tr(@"Convert");
	button.get_popup().add_icon_item(base_control.get_theme_icon(@"MeshDataInstance", @"EditorIcons"), tr(@"Convert to MeshDataInstance"), 0);
	#button.get_popup().add_icon_item(base_control.get_theme_icon(@"MeshInstance", @"EditorIcons"), tr(@"Merge to new MeshInstance"), 1);
	button.get_popup().connect(@"id_pressed", this, @"_on_id_pressed");
	
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, controls);
	
	controls.hide();
}

# Not called when exiting the editor, so we need to queue free our controls when this happens
void disable_plugin() {
	get_editor_interface().get_selection().disconnect(@"selection_changed", this, @"_on_selection_changed");
	
	if controls {
		controls.queue_free();
		controls = null;
	}
}

void _on_id_pressed(int id) {
	if id == 0 {
		convert_to_mdi();
	}
	#elif id == 1:
	#	merge_to_new_mi()
}

void _on_selection_changed() {
	Array sn = get_editor_interface().get_selection().get_selected_nodes();
	
	if sn.size() != 1 {
		controls.hide();
		return;
	}
	
	if !(sn[0] is MeshInstance) {
		controls.hide();
		return;
	}
	
	controls.show();
}
