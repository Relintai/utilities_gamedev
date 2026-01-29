tool;
extends Control;

PackedScene rect_editor_node_scene = preload("res://addons/world_generator/ui/RectViewNode.tscn");

export(NodePath) NodePath zoom_widget_path = "";

float _rect_scale = 1;

WorldGenBaseResource edited_resource = null;
Vector2 edited_resource_current_size = Vector2();

EditorPlugin _plugin = null;
UndoRedo _undo_redo = null;

void _enter_tree() {
	Node zoom_widget = get_node_or_null(zoom_widget_path);
	
	if !zoom_widget {
		return;
	}
	
	if !zoom_widget.is_connected("zoom_changed", this, "on_zoom_changed") {
		zoom_widget.connect("zoom_changed", this, "on_zoom_changed");
	}
	
	if !is_connected("visibility_changed", this, "on_visibility_changed") {
		connect("visibility_changed", this, "on_visibility_changed");
	}
}

void set_plugin(EditorPlugin plugin) {
	_plugin = plugin;
	_undo_redo = _plugin.get_undo_redo();
}

void on_visibility_changed() {
	call_deferred("apply_zoom");
}

void apply_zoom() {
	if !edited_resource {
		return;
	}
	
	Rect2 rect = edited_resource.rect;
	edited_resource_current_size = rect.size;
	rect.position = rect.position * _rect_scale;
	rect.size = rect.size * _rect_scale;
	set_custom_minimum_size(rect.size);
	
	MarginContainer p = get_parent() as MarginContainer;

	p.add_theme_constant_override("margin_left", min(rect.size.x / 4.0, 50 * _rect_scale));
	p.add_theme_constant_override("margin_right", min(rect.size.x / 4.0, 50 * _rect_scale));
	p.add_theme_constant_override("margin_top", min(rect.size.y / 4.0, 50 * _rect_scale));
	p.add_theme_constant_override("margin_bottom", min(rect.size.y / 4.0, 50 * _rect_scale));
	
	foreach Node c in get_children() {
		c.set_editor_rect_scale(_rect_scale);
	}
}

void on_zoom_changed(float zoom) {
	_rect_scale = zoom;
	apply_zoom();
}

void _draw() {
	draw_rect(Rect2(Vector2(), get_size()), Color(0.2, 0.2, 0.2, 1));
	
	float rsh = clamp(_rect_scale / 2.0, 1, 5);
	Color c = Color(0.4, 0.4, 0.4, 1);
	
	# Indicators that show the size of a unit (1 chunk)
	
	# Top left
	draw_line(Vector2(_rect_scale, 0), Vector2(_rect_scale, rsh), c);
	draw_line(Vector2(0, _rect_scale), Vector2(rsh, _rect_scale), c);
	
	# Top right
	draw_line(Vector2(get_size().x - _rect_scale, 0), Vector2(get_size().x - _rect_scale, rsh), c);
	draw_line(Vector2(get_size().x - rsh, _rect_scale), Vector2(get_size().x, _rect_scale), c);
	
	# Bottom left
	draw_line(Vector2(_rect_scale, get_size().y - rsh), Vector2(_rect_scale, get_size().y), c);
	draw_line(Vector2(0, get_size().y - _rect_scale), Vector2(rsh, get_size().y - _rect_scale), c);
	
	# Bottom right
	draw_line(Vector2(get_size().x - _rect_scale, get_size().y - rsh), Vector2(get_size().x - _rect_scale, get_size().y), c);
	draw_line(Vector2(get_size().x - rsh, get_size().y - _rect_scale), Vector2(get_size().x, get_size().y - _rect_scale), c);
	
	if edited_resource {
		edited_resource.editor_draw_additional_background(this);
	}
}

void refresh() {
	clear();
	
	if !edited_resource {
		return;
	}
	
	Rect2 rect = edited_resource.rect;
	edited_resource_current_size = rect.size;
	rect.position = rect.position * _rect_scale;
	rect.size = rect.size * _rect_scale;
	set_custom_minimum_size(rect.size);
	
	apply_zoom();
	
	refresh_rects();
}

void clear() {
	
}

void refresh_rects() {
	clear_rects();
	
	if !edited_resource {
		return;
	}
	
	Array cont = edited_resource.get_content();
	
	foreach Variant c in cont {
		if c {
			Node s = rect_editor_node_scene.instance();
			
			add_child(s);
			s.set_plugin(_plugin);
			s.set_editor_rect_scale(_rect_scale);
			s.edited_resource_parent_size = edited_resource_current_size;
			s.set_edited_resource(c);
		}
	}
}

void clear_rects() {
	foreach Node c in get_children() {
		c.queue_free();
		remove_child(c);
	}
}

void set_edited_resource(WorldGenBaseResource res) {
	if edited_resource {
		edited_resource.disconnect("changed", this, "on_edited_resource_changed");
	}
	
	edited_resource = res;
	
	refresh();
	
	if edited_resource {
		edited_resource.connect("changed", this, "on_edited_resource_changed");
	}
}

void on_edited_resource_changed() {
	call_deferred("refresh");
}
