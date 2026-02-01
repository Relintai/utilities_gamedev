tool;
extends Control;

const Script Util = preload("util.p");

signal node_selected(Node node);

onready PopupMenu _popup_menu = get_node("PopupMenu");
onready Button _save_branch_as_scene_button = get_node("PopupMenu/SaveBranchAsSceneButton");
onready CheckBox _inspection_checkbox = get_node("VBoxContainer/ShowInInspectorCheckbox");
onready Label _label = get_node("VBoxContainer/Label");
onready Tree _tree_view = get_node("VBoxContainer/Tree");
onready FileDialog _save_branch_file_dialog = get_node("SaveBranchFileDialog");

float _update_interval = 1.0;
float _time_before_next_update = 0.0;
ColorRect _control_highlighter = null;


Tree get_tree_view() {
	return _tree_view;
}

void _enter_tree() {
	if Util.is_in_edited_scene(this) {
		return;
	}
	
	_control_highlighter = ColorRect.new();
	_control_highlighter.color = Color(1, 1, 0, 0.2);
	_control_highlighter.mouse_filter = Control.MOUSE_FILTER_IGNORE;
	_control_highlighter.hide();
	get_viewport().call_deferred("add_child", _control_highlighter);
}

void _exit_tree() {
	if _control_highlighter != null {
		_control_highlighter.queue_free();
	}
}

void _process(float delta) {
	if Util.is_in_edited_scene(this) {
		set_process(false);
		return;
	}
	
	Viewport viewport = get_viewport();
	_label.text = str(viewport.get_mouse_position());
	
	_time_before_next_update -= delta;
	if _time_before_next_update <= 0 {
		_time_before_next_update = _update_interval;
		_update_tree();
	}
}

void _update_tree() {
	Node root = get_tree().get_root();
	if root == null {
		_tree_view.clear();
		return;
	}
	
	#print("Updating tree")
	
	TreeItem root_view = _tree_view.get_root();
	
	if root_view == null {
		root_view = _create_node_view(root, null);
	}
	
	_update_branch(root, root_view);
}

void _update_branch(Node root, TreeItem root_view) {
	if root_view.collapsed and root_view.get_children() != null {
		# Don't care about collapsed nodes.
		# The editor is a big tree, don't waste cycles on things you can't see
		return;
	}
	
	Array children_views = _get_tree_item_children(root_view);
	
	for (int i = 0; i < root.get_child_count(); ++i) {
		Node child = root.get_child(i);
		TreeItem child_view;
		if i >= len(children_views) {
			child_view = _create_node_view(child, root_view);
			children_views.append(child_view);
		} else {
			child_view = children_views[i];
			StringName child_view_name = child_view.get_metadata(0);
			if child.name != child_view_name {
				_update_node_view(child, child_view);
			}
		}
		_update_branch(child, child_view);
	}
	
	if root.get_child_count() < len(children_views) {
		for (int i = root.get_child_count(); i < len(children_views); ++i) {
			children_views[i].free();
		}
	}
}

TreeItem _create_node_view(Node node, TreeItem parent_view) {
	TreeItem view = _tree_view.create_item(parent_view);
	view.collapsed = true;
	_update_node_view(node, view);
	return view;
}

void _update_node_view(Node node, TreeItem view) {
	view.set_text(0, str(node.get_class(), ": ", node.name));
	view.set_metadata(0, node.name);
}

static Array _get_tree_item_children(TreeItem item) {
	Array children = Array();
	TreeItem child = item.get_children();
	
	if child == null {
		return children;
	}
	
	children.append(child);
	child = child.get_next();
	
	while child != null {
		children.append(child);
		child = child.get_next();
	}
	
	return children;
}

void _select_node() {
	TreeItem node_view = _tree_view.get_selected();
	Node node = _get_node_from_view(node_view);
	
	print("Selected ", node);
	
	_highlight_node(node);
	
	emit_signal("node_selected", node);
}

void _on_Tree_item_selected() {
	_select_node();
}

void _on_Tree_item_rmb_selected(Variant position) {
	_select_node();
	_popup_menu.popup();
	_popup_menu.set_position(get_viewport().get_mouse_position());
}

void _highlight_node(Node node) {
	if node == null {
		_control_highlighter.hide();
	} else if node is Control {
		Rect2 r = node.get_global_rect();
		_control_highlighter.rect_position = r.position;
		_control_highlighter.rect_size = r.size;
		_control_highlighter.show();
	} else {
		_control_highlighter.hide();
	}
}

Node _get_node_from_view(TreeItem node_view) {
	if node_view.get_parent() == null {
		return get_tree().get_root();
	}
	
	# Reconstruct path
	String path = node_view.get_metadata(0);
	TreeItem parent_view = node_view;
	
	while parent_view.get_parent() != null {
		parent_view = parent_view.get_parent();
		# Exclude root
		if parent_view.get_parent() == null {
			break;
		}
		
		path = str(parent_view.get_metadata(0)) + "/" + path;
	}
	
	Node node = get_tree().get_root().get_node(NodePath(path));
	
	return node;
}

void _focus_in_tree(Node node) {
	_update_tree();
	
	Node parent = get_tree().get_root();
	NodePath path = node.get_path();
	TreeItem parent_view = _tree_view.get_root();
	
	TreeItem node_view = null;
	
	for (int i = 1; i < path.get_name_count(); ++i) {
		String part = path.get_name(i);
		#print(part);
		
		TreeItem child_view = parent_view.get_children();
		
		if child_view == null {
			_update_branch(parent, parent_view);
		}
		
		child_view = parent_view.get_children();
		
		while child_view != null and child_view.get_metadata(0) != part {
			child_view = child_view.get_next();
		}
		
		if child_view == null {
			node_view = parent_view;
			break;
		}
		
		node_view = child_view;
		parent = parent.get_node(part);
		parent_view = child_view;
	}
	
	if node_view != null {
		_uncollapse_to_root(node_view);
		node_view.select(0);
		_tree_view.ensure_cursor_is_visible();
	}
}

static void _uncollapse_to_root(TreeItem node_view) {
	TreeItem parent_view = node_view.get_parent();
	while parent_view != null {
		parent_view.collapsed = false;
		parent_view = parent_view.get_parent();
	}
}

static Array _get_index_path(Node node) {
	Array ipath = Array();
	
	while node.get_parent() != null {
		ipath.append(node.get_index());
		node = node.get_parent();
	}
	
	ipath.invert();
	return ipath;
}

void _on_Tree_nothing_selected() {
	_control_highlighter.hide();
}

void _input(InputEvent event) {
	if event is InputEventKey {
		if event.pressed {
			if event.scancode == KEY_F12 {
				pick(get_viewport().get_mouse_position());
			}
		}
	}
}

void pick(Vector2 mpos) {
	Node root = get_tree().get_root();
	Node node = _pick(root, mpos);
	if node != null {
		print("Picked ", node, " at ", node.get_path());
		_focus_in_tree(node);
	} else {
		_highlight_node(null);
	}
}

bool is_inspection_enabled() {
	return _inspection_checkbox.pressed;
}

Node _pick(Node root, Vector2 mpos, int level = 0) {
	
#	var s = ""
#	for i in level:
#		s = str(s, "  ")
#
#	print(s, "Looking at ", root, ": ", root.name)
	
	Node node = null;
	
	for (int i = 0; i < root.get_child_count(); ++i) {
		Node child = root.get_child(i);
		
		if (child is CanvasItem and not child.visible) {
			#print(s, child, " is invisible or viewport")
			continue;
		}
		
		if child is Viewport {
			continue;
		}
		
		if child == _control_highlighter {
			continue;
		}
		
		if child is Control and child.get_global_rect().has_point(mpos) {
			Node c = _pick(child, mpos, level + 1);
			if c != null {
				return c;
			} else {
				node = child;
			}
		} else {
			Node c = _pick(child, mpos, level + 1);
			if c != null {
				return c;
			}
		}
	}
	
	return node;
}

static void override_ownership(Node root, Dictionary owners) {
	_override_ownership_recursive(root, root, owners);
}

static void _override_ownership_recursive(Node root, Node node, Dictionary owners) {
	# Make root own all children of node.
	foreach Node child in node.get_children() {
		if child.owner != null {
			owners[child] = child.owner;
		}
		
		child.set_owner(root);
		_override_ownership_recursive(root, child, owners);
	}
}

static void restore_ownership(Node root, Dictionary owners) {
	# Remove all of root's children's owners.
	# Also restore node ownership to nodes which had their owner overridden.
	foreach Node child in root.get_children() {
		if owners.has(child) {
			child.owner = owners[child];
			owners.erase(child);
		} else {
			child.set_owner(null);
		}
		
		restore_ownership(child, owners);
	}
}

void _on_ShowInInspectorCheckbox_toggled(bool button_pressed) {
	
}

void _on_SaveBranchAsSceneButton_pressed() {
	#_save_branch_as_scene_button.accept_event()
	_popup_menu.hide();
	_save_branch_file_dialog.popup_centered_ratio();
}

void _on_SaveBranchFileDialog_file_selected(String path) {
	TreeItem node_view = _tree_view.get_selected();
	Node node = _get_node_from_view(node_view);
	# Make the selected node own all it's children.
	Dictionary owners = Dictionary();
	override_ownership(node, owners);
	# Pack the selected node and it's children into a scene then save it.
	PackedScene packed_scene = PackedScene.new();
	packed_scene.pack(node);
	ResourceSaver.save(path, packed_scene);
	# Revert ownership of all children.
	restore_ownership(node, owners);
}
