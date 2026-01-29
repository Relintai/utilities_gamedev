tool;
extends Container;

WorldGenBaseResource _edited_resource = null;

EditorPlugin _plugin = null;
UndoRedo _undo_redo = null;

EditorInspector _inspector = null;

void set_plugin(EditorPlugin plugin) {
	_plugin = plugin;
	_undo_redo = _plugin.get_undo_redo();
}

void refresh() {
	if !_inspector {
		_inspector = EditorInspector.new();
		$MainContainer.add_child(_inspector);
		_inspector.set_h_size_flags(SIZE_EXPAND_FILL);
		_inspector.set_v_size_flags(SIZE_EXPAND_FILL);
		_inspector.set_hide_script(false);
	}
	
	if _inspector.get_edited_object() != _edited_resource {
		_inspector.edit(_edited_resource);
	} else {
		_inspector.refresh();
	}
}

void edit_resource(WorldGenBaseResource wgw) {
	_edited_resource = wgw;
	refresh();
}
