tool;
extends Control;

signal inspect_data();
signal duplicate();
signal delete();

export(PackedScene) PackedScene spatial_preview;
export(PackedScene) PackedScene node2d_preview;
export(PackedScene) PackedScene control_preview;
export(PackedScene) PackedScene texture_preview;

export(NodePath) NodePath main_button_path;

Button _main_button;

Node _preview;
Resource _data;

void _ready() {
	_main_button = get_node(main_button_path) as Button;
}

void set_resource(Resource data) {
	_data = data;
	
	_main_button.set_resource(data);
	
	String name_text = "";
	
	if data.has_method("get_id") {
		name_text += str(data.get_id()) + " - ";
	}
	
	if data.has_method("get_text_name") {
		name_text += str(data.get_text_name());
	} else {
		if data.resource_name != "" {
			name_text += data.resource_name;
		} else {
			name_text += data.resource_path;
		}
	}
	
	if data.has_method("get_rank") {
		name_text +=  " - Rank " + str(data.get_rank());
	}
	
	if data is Texture {
		_preview = texture_preview.instance();
		add_child(_preview);
		_preview.owner = this;
		move_child(_preview, 0);
			
		_preview.set_texture(data as Texture);
	} else if data is PackedScene {
		Node n = data.instance();
		
		if _preview != null {
			_preview.queue_free();
		}
		
		if n is Spatial {
			_preview = spatial_preview.instance();
			add_child(_preview);
			_preview.owner = this;
			move_child(_preview, 0);
			
			_preview.preview(n as Spatial);
		} else if n is Node2D {
			_preview = node2d_preview.instance();
			add_child(_preview);
			_preview.owner = this;
			move_child(_preview, 0);
			
			_preview.preview(n as Node2D);
		} else if n is Control {
			_preview = control_preview.instance();
			add_child(_preview);
			_preview.owner = this;
			move_child(_preview, 0);
			
			_preview.preview(n as Control);
		} else {
			n.queue_free();
		}
	}
	
	_main_button.text = name_text;
}

bool can_drop_data(Vector2 position, Variant data) {
	return false;
}

void inspect() {
	emit_signal("inspect_data", _data);
}

void duplicate_data() {
	emit_signal("duplicate", _data);
}

void delete() {
	emit_signal("delete", _data);
}
