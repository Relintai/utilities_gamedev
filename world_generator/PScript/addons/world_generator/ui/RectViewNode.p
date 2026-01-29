tool;
extends MarginContainer;

enum DragType {
	DRAG_NONE = 0,
	DRAG_MOVE = 1,
	DRAG_RESIZE_TOP = 1 << 1,
	DRAG_RESIZE_RIGHT = 1 << 2,
	DRAG_RESIZE_BOTTOM = 1 << 3,
	DRAG_RESIZE_LEFT = 1 << 4
};

WorldGenBaseResource edited_resource = null;
Vector2 edited_resource_parent_size = Vector2();

Color _edited_resource_rect_border_color = Color(1, 1, 1, 1);
Color _edited_resource_rect_color = Color(0.8, 0.8, 0.8, 0.9);
int _editor_rect_border_size = 2;
Color _edited_resource_font_color = Color(0, 0, 0, 1);
String _editor_additional_text = "";

int drag_type;
Vector2 drag_offset;
Vector2 drag_offset_far;

float _rect_scale = 1;

bool _edited_resource_event_ignore = false;

EditorPlugin _plugin = null;
UndoRedo _undo_redo = null;

void set_plugin(EditorPlugin plugin) {
	_plugin = plugin;
	_undo_redo = _plugin.get_undo_redo();
}

void _draw() {
	draw_rect(Rect2(Vector2(), get_size()), _edited_resource_rect_color);
	draw_rect(Rect2(Vector2(), get_size()), _edited_resource_rect_border_color, false, _editor_rect_border_size);
	
	Font font = get_theme_font("font");
	
	String res_name = "NULL";
	
	if edited_resource {
		res_name = edited_resource.resource_name;
	}
	
	String res_cls = "";
	
	if edited_resource {
		res_cls = edited_resource.get_editor_class();
	}
	
	draw_string(font, Vector2(_editor_rect_border_size, font.get_height()), res_name, _edited_resource_font_color);

	if res_cls != "" {
		draw_string(font, Vector2(_editor_rect_border_size, font.get_height() * 2), res_cls, _edited_resource_font_color, get_rect().size.x);
	}
	
	if _editor_additional_text != "" {
		draw_string(font, Vector2(_editor_rect_border_size, font.get_height() * 3), _editor_additional_text, _edited_resource_font_color, get_rect().size.x);
	}
	
	if edited_resource {
		edited_resource.editor_draw_additional(this);
	}
}

void refresh() {
	if !edited_resource {
		return;
	}
	
	#anchor is bottom left here
	Rect2 rect = edited_resource.get_rect();
	rect.position *= _rect_scale;
	rect.size *= _rect_scale;
	
	#anchor needs to be on top left here
	Vector2 rp = rect.position;
	rp.y = edited_resource_parent_size.y * _rect_scale - rect.size.y - rect.position.y;
	rect_position = rp;
	rect_size = rect.size;
	
	update();
}

void set_editor_rect_scale(float rect_scale) {
	_rect_scale = rect_scale;
	
	refresh();
}

void set_edited_resource(WorldGenBaseResource res) {
	edited_resource = res;
	
	if edited_resource {
		_edited_resource_rect_border_color = edited_resource.get_editor_rect_border_color();
		_edited_resource_rect_color = edited_resource.get_editor_rect_color();
		_editor_rect_border_size = edited_resource.get_editor_rect_border_size();
		_edited_resource_font_color = edited_resource.get_editor_font_color();
		_editor_additional_text = edited_resource.get_editor_additional_text();
	
		edited_resource.connect("changed", this, "on_edited_resource_changed");
	}
	
	refresh();
}

void on_edited_resource_changed() {
	if _edited_resource_event_ignore {
		return;
	}
	
	refresh();
}

#based on / ported from engine/scene/gui/dialogs.h and .cpp
void _notification(int p_what) {
	if (p_what == NOTIFICATION_MOUSE_EXIT) {
		// Reset the mouse cursor when leaving the resizable window border.
		if (edited_resource && !edited_resource.locked && !drag_type) {
			if (get_default_cursor_shape() != CURSOR_ARROW) {
				set_default_cursor_shape(CURSOR_ARROW);
			}
		}
	}
}

#based on / ported from engine/scene/gui/dialogs.h and .cpp
void _gui_input(InputEvent p_event) {
	if !edited_resource {
		return;
	}
	
	if (p_event is InputEventMouseButton) && (p_event.get_button_index() == BUTTON_LEFT) {
		InputEventMouseButton mb = p_event as InputEventMouseButton;
		
		if (mb.is_pressed()) {
			# Begin a possible dragging operation.
			drag_type = _drag_hit_test(Vector2(mb.get_position().x, mb.get_position().y));
			
			if (drag_type != DragType.DRAG_NONE) {
				drag_offset = get_global_mouse_position() - get_position();
			}
			
			drag_offset_far = get_position() + get_size() - get_global_mouse_position();
			
		} else if (drag_type != DragType.DRAG_NONE && !mb.is_pressed()) {
			# End a dragging operation.
			drag_type = DragType.DRAG_NONE;
			
			Rect2 rect = get_rect();
			#rect needs to be converted back
			rect.position.y = edited_resource_parent_size.y * _rect_scale - rect.size.y - rect.position.y;
			rect.position /= _rect_scale;
			rect.size /= _rect_scale;
			
			#edited_resource.set_rect(rect)
			_edited_resource_event_ignore = true;
			_undo_redo.create_action("WE: Drag End");
			_undo_redo.add_do_method(edited_resource, "set_rect", rect);
			_undo_redo.add_undo_method(edited_resource, "set_rect", edited_resource.get_rect());
			_undo_redo.commit_action();
			_edited_resource_event_ignore = false;
		}
	}
	
	if p_event is InputEventMouseMotion {
		InputEventMouseMotion mm = p_event as InputEventMouseMotion;

		if (drag_type == DragType.DRAG_NONE) {
			# Update the cursor while moving along the borders.
			int cursor = CURSOR_ARROW;
			if (!edited_resource.locked) {
				int preview_drag_type = _drag_hit_test(Vector2(mm.get_position().x, mm.get_position().y));
				
				int top_left = DragType.DRAG_RESIZE_TOP + DragType.DRAG_RESIZE_LEFT;
				int bottom_right = DragType.DRAG_RESIZE_BOTTOM + DragType.DRAG_RESIZE_RIGHT;
				int top_right = DragType.DRAG_RESIZE_TOP + DragType.DRAG_RESIZE_RIGHT;
				int bottom_left = DragType.DRAG_RESIZE_BOTTOM + DragType.DRAG_RESIZE_LEFT;
				
				switch (preview_drag_type) {
					case DragType.DRAG_RESIZE_TOP:
						cursor = CURSOR_VSIZE;
						break;
					case DragType.DRAG_RESIZE_BOTTOM:
						cursor = CURSOR_VSIZE;
						break;
					case DragType.DRAG_RESIZE_LEFT:
						cursor = CURSOR_HSIZE;
						break;
					case DragType.DRAG_RESIZE_RIGHT:
						cursor = CURSOR_HSIZE;
						break;
					case top_left:
						cursor = CURSOR_FDIAGSIZE;
						break;
					case bottom_right:
						cursor = CURSOR_FDIAGSIZE;
						break;
					case top_right:
						cursor = CURSOR_BDIAGSIZE;
						break;
					case bottom_left:
						cursor = CURSOR_BDIAGSIZE;
						break;
				}
			}
			
			if (get_cursor_shape() != cursor) {
				set_default_cursor_shape(cursor);
			}
		} else {
			# Update while in a dragging operation.
			Vector2 global_pos = get_global_mouse_position();

			Rect2 rect = get_rect();
			Vector2 min_size = get_combined_minimum_size();

			if (drag_type == DragType.DRAG_MOVE) {
				rect.position = global_pos - drag_offset;
			} else {
				if (drag_type & DragType.DRAG_RESIZE_TOP) {
					int bottom = rect.position.y + rect.size.y;
					int max_y = bottom - min_size.y;
					rect.position.y = min(global_pos.y - drag_offset.y, max_y);
					rect.size.y = bottom - rect.position.y;
				} else if (drag_type & DragType.DRAG_RESIZE_BOTTOM) {
					rect.size.y = global_pos.y - rect.position.y + drag_offset_far.y;
				}
				
				if (drag_type & DragType.DRAG_RESIZE_LEFT) {
					int right = rect.position.x + rect.size.x;
					int max_x = right - min_size.x;
					rect.position.x = min(global_pos.x - drag_offset.x, max_x);
					rect.size.x = right - rect.position.x;
				} else if (drag_type & DragType.DRAG_RESIZE_RIGHT) {
					rect.size.x = global_pos.x - rect.position.x + drag_offset_far.x;
				}
			}
			
			set_size(rect.size);
			set_position(rect.position);
		}
	}
}

#based on / ported from engine/scene/gui/dialogs.h and .cpp
int _drag_hit_test(Vector2 pos) {
	int drag_type = DragType.DRAG_NONE;

	if (!edited_resource.locked) {
		int scaleborder_size = 5; #get_constant("scaleborder_size", "WindowDialog")

		Rect2 rect = get_rect();

		if (pos.y < (scaleborder_size)) {
			drag_type = DragType.DRAG_RESIZE_TOP;
		} else if (pos.y >= (rect.size.y - scaleborder_size)) {
			drag_type = DragType.DRAG_RESIZE_BOTTOM;
		}
		
		if (pos.x < scaleborder_size) {
			drag_type |= DragType.DRAG_RESIZE_LEFT;
		} else if (pos.x >= (rect.size.x - scaleborder_size)) {
			drag_type |= DragType.DRAG_RESIZE_RIGHT;
		}
		
		if (drag_type == DragType.DRAG_NONE) {
			drag_type = DragType.DRAG_MOVE;
		}
	}
	
	return drag_type;
}
