tool;
extends Resource;
class_name WorldGenBaseResource;

export(Rect2) Rect2 rect = Rect2(0, 0, 100, 100);
export(Vector2i) Vector2i min_size = Vector2i(1, 1);
export(Vector2i) Vector2i max_size = Vector2i(1000000, 1000000);
export(bool) bool locked = false;

Rect2 get_rect() {
	return rect;
}

void set_rect(Rect2 r) {
	rect.position = r.position;
	rect.size.x = max(min_size.x, r.size.x);
	rect.size.y = max(min_size.y, r.size.y);
	rect.size.x = min(max_size.x, rect.size.x);
	rect.size.y = min(max_size.y, rect.size.y);
	emit_changed();
}

Vector2i get_min_size() {
	return min_size;
}

void set_min_size(Vector2i r) {
	min_size = r;
	emit_changed();
}

Vector2i get_max_size() {
	return max_size;
}

void set_max_size(Vector2i r) {
	max_size = r;
	emit_changed();
}

bool get_locked() {
	return locked;
}

void set_locked(bool r) {
	locked = r;
	emit_changed();
}

Array get_content() {
	return Array();
}

void set_content(Array arr) {
}

void add_content(WorldGenBaseResource entry) {
}

void create_content(String item_name = "") {
	
}

void remove_content_entry(WorldGenBaseResource entry) {
}

bool is_spawner() {
	return _is_spawner();
}

bool _is_spawner() {
	return false;
}

Vector2 get_spawn_local_position() {
	return _get_spawn_local_position();
}

Vector2 _get_spawn_local_position() {
	return Vector2();
}

Array get_spawn_positions(Vector2 parent_position = Vector2()) {
	if is_spawner() {
		return [ [ resource_name, parent_position + rect.position + get_spawn_local_position() ] ];
	}
	
	Array spawners;
	Vector2 p = parent_position + rect.position;
		
	foreach Variant c in get_content() {
		if c {
			spawners.append_array(c.get_spawn_positions(p));
		}
	}
	
	return spawners;
}

WorldGenBaseResource get_content_with_name(String name) {
	if resource_name == name {
		return this;
	}
	
	foreach Variant c in get_content() {
		if c {
			Variant cc = c.get_content_with_name(name);
			if cc {
				return cc;
			}
		}
	}
	
	return null;
}

Array get_all_contents_with_name(String name) {
	Array arr = Array();
	
	if resource_name == name {
		arr.append(this);
	}
	
	foreach Variant c in get_content() {
		if c {
			Array cc = c.get_all_contents_with_name(name);
			arr.append_array(cc);
		}
	}
	
	return arr;
}

WorldGenBaseResource duplicate_content_entry(WorldGenBaseResource entry, bool add = true) {
	WorldGenBaseResource de = entry.duplicate(true);
	de.resource_name += " (Duplicate)";
	
	if add {
		add_content(de);
	}
	
	return de;
}

void setup_terra_library(TerrainLibrary library, int pseed) {
	_setup_terra_library(library, pseed);
	
	foreach Variant c in get_content() {
		if c {
			c.setup_terra_library(library, pseed);
		}
	}
}

void _setup_terra_library(TerrainLibrary library, int pseed) {
	
}

void generate_terra_chunk(TerrainChunk chunk, int pseed, bool spawn_mobs) {
	Vector2 p = Vector2(chunk.get_position_x(), chunk.get_position_z());

	WorldGenRaycast raycast = get_hit_stack(p);
	
	if raycast.size() == 0 {
		_generate_terra_chunk_fallback(chunk, pseed, spawn_mobs);
		return;
	}
	
	while raycast.next() {
		raycast.get_resource()._generate_terra_chunk(chunk, pseed, spawn_mobs, raycast);
	}
}

void _generate_terra_chunk(TerrainChunk chunk, int pseed, bool spawn_mobs, WorldGenRaycast raycast) {
}

void _generate_terra_chunk_fallback(TerrainChunk chunk, int pseed, bool spawn_mobs) {
	chunk.channel_ensure_allocated(TerrainChunkDefault.DEFAULT_CHANNEL_TYPE, 1);
	chunk.channel_ensure_allocated(TerrainChunkDefault.DEFAULT_CHANNEL_ISOLEVEL, 1);
	chunk.set_data(1, 0, 0, TerrainChunkDefault.DEFAULT_CHANNEL_ISOLEVEL);
}

Image generate_map(int pseed) {
	Image img = Image.new();
	
	img.create(get_rect().size.x, get_rect().size.y, false, Image.FORMAT_RGBA8);
	
	add_to_map(img, pseed);
	
	return img;
}

void add_to_map(Image img, int pseed) {
	_add_to_map(img, pseed);
	
	foreach Variant c in get_content() {
		if c {
			c.add_to_map(img, pseed);
		}
	}
}

void _add_to_map(Image img, int pseed) {
	
}

WorldGenRaycast get_hit_stack(Vector2 pos, WorldGenRaycast raycast = null) {
	Rect2 r = get_rect();
	Vector2 local_pos = pos - rect.position;
	r.position = Vector2();

	if !raycast {
		raycast = WorldGenRaycast.new();
	}
	
	if r.has_point(local_pos) {
		Vector2 local_uv = local_pos / rect.size;
		raycast.add_data(this, local_pos, local_uv);
	}
	
	foreach Variant c in get_content() {
		if c {
			c.get_hit_stack(local_pos, raycast);
		}
	}
	
	return raycast;
}

Color get_editor_rect_border_color() {
	return Color(1, 1, 1, 1);
}

Color get_editor_rect_color() {
	return Color(1, 1, 1, 0.9);
}

int get_editor_rect_border_size() {
	return 2;
}

Color get_editor_font_color() {
	return Color(0, 0, 0, 1);
}

String get_editor_class() {
	return "WorldGenBaseResource";
}

String get_editor_additional_text() {
	return "";
}

void editor_draw_additional(Control control) {
	_editor_draw_additional(control);
}

void _editor_draw_additional(Control control) {
}

void editor_draw_additional_background(Control control) {
	_editor_draw_additional_background(control);
}

void _editor_draw_additional_background(Control control) {
}
