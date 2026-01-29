tool
extends Container

var _edited_resource : WorldGenBaseResource = null

var _plugin : EditorPlugin = null
var _undo_redo : UndoRedo = null

var _inspector : EditorInspector = null

func set_plugin(plugin : EditorPlugin) -> void:
	_plugin = plugin
	_undo_redo = _plugin.get_undo_redo()

func refresh() -> void:
	if !_inspector:
		_inspector = EditorInspector.new()
		$MainContainer.add_child(_inspector)
		_inspector.set_h_size_flags(SIZE_EXPAND_FILL)
		_inspector.set_v_size_flags(SIZE_EXPAND_FILL)
		_inspector.set_hide_script(false)
	
	if _inspector.get_edited_object() != _edited_resource:
		_inspector.edit(_edited_resource)
	else:
		_inspector.refresh()

func edit_resource(wgw) -> void:
	_edited_resource = wgw
	refresh()
