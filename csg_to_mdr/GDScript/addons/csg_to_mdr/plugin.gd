tool
extends EditorPlugin

var controls : HBoxContainer = null

func array_mesh_to_mdr(mesh : ArrayMesh) -> MeshDataResource:
	var mdr : MeshDataResource = MeshDataResource.new()
	
	if mesh.get_surface_count() > 0:
		mdr.array = mesh.surface_get_arrays(0)
	
	return mdr

func convert_to_mdi() -> void:
	var md : Array = get_current_root_mesh()
		
	if md.size() == 0:
		return
	
	var cs : CSGShape = md[0]
	var mesh : ArrayMesh = md[1]
	
	var n : Node = Node.new()
	n.name = "NewNodes"
	cs.add_child(n)
	n.owner = get_editor_interface().get_edited_scene_root()
	
	var mdi : MeshDataInstance = MeshDataInstance.new()
	mdi.transform = cs.transform
	mdi.mesh_data = array_mesh_to_mdr(mesh)
	n.add_child(mdi)
	mdi.owner = get_editor_interface().get_edited_scene_root()
	
	
func convert_to_mi() -> void:
	var md : Array = get_current_root_mesh()
		
	if md.size() == 0:
		return
	
	var cs : CSGShape = md[0]
	var mesh : ArrayMesh = md[1]
	
	var n : Node = Node.new()
	n.name = "NewNodes"
	cs.add_child(n)
	n.owner = get_editor_interface().get_edited_scene_root()
	
	var mi : MeshInstance = MeshInstance.new()
	mi.transform = cs.transform
	mi.mesh = mesh
	n.add_child(mi)
	mi.owner = get_editor_interface().get_edited_scene_root()

func get_current_root_mesh() -> Array:
	var sn : Array = get_editor_interface().get_selection().get_selected_nodes()
	
	if sn.size() != 1:
		return []
		
	if !(sn[0] is CSGShape):
		return []
		
	var cs : CSGShape = sn[0] as CSGShape
	
	if !cs.is_root_shape():
		return []
		
	var meshes : Array = cs.get_meshes()
	
	if meshes.size() < 2:
		return []
		
	var mesh : ArrayMesh = meshes[1]
	
	return [ cs, mesh ]

func _enter_tree() -> void:
	# We need to do this, because we don't want to take over CSG's editor plugin
	get_editor_interface().get_selection().connect(@"selection_changed", self, @"_on_selection_changed")
	
	var base_control : Control = get_editor_interface().get_base_control()
	
	controls = HBoxContainer.new()
	
	controls.add_child(VSeparator.new())
	var button : MenuButton = MenuButton.new()
	controls.add_child(button)
	button.icon = base_control.get_theme_icon(@"CSGBox", @"EditorIcons")
	button.hint_tooltip = tr(@"Convert")
	button.get_popup().add_icon_item(base_control.get_theme_icon(@"MeshInstance", @"EditorIcons"), tr(@"Convert to MeshInstance"), 0)
	button.get_popup().add_icon_item(base_control.get_theme_icon(@"MeshDataInstance", @"EditorIcons"), tr(@"Convert to MeshDataInstance"), 1)
	button.get_popup().connect(@"id_pressed", self, @"_on_id_pressed")
	
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, controls)
	
	controls.hide()

# Not called when exiting the editor, so we need to queue free our controls when this happens
func disable_plugin() -> void:
	get_editor_interface().get_selection().disconnect(@"selection_changed", self, @"_on_selection_changed")
	
	if controls:
		controls.queue_free()
		controls = null

func _on_id_pressed(id : int) -> void:
	if id == 0:
		convert_to_mi()
	elif id == 1:
		convert_to_mdi()

func _on_selection_changed() -> void:
	var sn : Array = get_editor_interface().get_selection().get_selected_nodes()
	
	if sn.size() != 1:
		controls.hide()
		return
		
	if !(sn[0] is CSGShape):
		controls.hide()
		return
		
	var cs : CSGShape = sn[0] as CSGShape
	
	if !cs.is_root_shape():
		controls.hide()
		return
		
	controls.show()
