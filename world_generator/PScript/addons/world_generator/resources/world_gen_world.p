tool;
extends WorldGenBaseResource;
class_name WorldGenWorld;

export(Array, Continent) Array continents;

Array get_content() {
	return continents;
}

void set_content(Array arr) {
	continents = arr;
}

void create_content(String item_name = "") {
	Continent continent = Continent.new();
	continent.resource_name = item_name;

	add_content(continent);
}

void add_content(WorldGenBaseResource entry) {
	Rect2 r = get_rect();
	r.position = Vector2();
	r.size.x /= 10.0;
	r.size.y /= 10.0;
	
	entry.set_rect(r);
	
	continents.append(entry);
	emit_changed();
}

void remove_content_entry(WorldGenBaseResource entry) {
	for (int i = 0; i < continents.size(); ++i) {
		if continents[i] == entry {
			continents.remove(i);
			emit_changed();
			return;
		}
	}
}

void generate_terra_chunk(TerrainChunk chunk, int pseed, bool spawn_mobs) {
	Vector2 p = Vector2(chunk.get_position_x(), chunk.get_position_z());

	WorldGenRaycast raycast = get_hit_stack(p);
	
	if raycast.size() == 0 {
		_generate_terra_chunk_fallback(chunk, pseed, spawn_mobs);
		return;
	}
	
	_generate_terra_chunk(chunk, pseed, spawn_mobs, raycast);
	
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
