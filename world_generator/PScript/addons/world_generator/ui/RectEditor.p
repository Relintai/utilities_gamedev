tool;
extends PanelContainer;

WorldGenBaseResource last_edited_res = null;

void set_plugin(EditorPlugin plugin) {
	get_node("ScrollContainer/MarginContainer/RectView").set_plugin(plugin);
}

void set_edited_resource(WorldGenBaseResource res) {
	get_node("ScrollContainer/MarginContainer/RectView").set_edited_resource(res);
	
	if res && res != last_edited_res {
		Rect2 r = res.get_rect();
		last_edited_res = res;
		
		int axis = 0;
		
		if r.size.x > r.size.y {
			axis = Vector2.AXIS_X;
		} else {
			axis = Vector2.AXIS_Y;
		}
		
		if r.size[axis] > 0 {
			float rsx = get_node("ScrollContainer").rect_size[axis];
			float scale = rsx / r.size[axis] * 0.5;
			
			get_node("Control/EditorZoomWidget").zoom = scale;
			get_node("ScrollContainer/MarginContainer/RectView").apply_zoom();
	
			ScrollBar sb = get_node("ScrollContainer").get_h_scrollbar();
			sb.ratio = 1;
			
			sb = get_node("ScrollContainer").get_v_scrollbar();
			sb.ratio = 1;
		}
	}
}
