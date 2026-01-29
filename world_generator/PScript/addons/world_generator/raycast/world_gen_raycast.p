tool;
extends Reference;
class_name WorldGenRaycast;

int current_index = -1;
Array base_resources = Array();
PoolVector2Array local_positions = PoolVector2Array();
PoolVector2Array local_uvs = PoolVector2Array();

Vector2 get_local_position() {
	return local_positions[current_index];
}

Vector2 get_local_uv() {
	return local_uvs[current_index];
}

# WorldGenBaseResource (can't explicitly add -> cyclic dependency)
Resource get_resource() {
	return base_resources[current_index];
}

bool next() {
	current_index += 1;
	
	return base_resources.size() > current_index;
}

int size() {
	return base_resources.size();
}

# WorldGenBaseResource (can't explicitly add -> cyclic dependency)
void add_data(Resource base_resource, Vector2 local_pos, Vector2 local_uv) {
	base_resources.append(base_resource);
	local_positions.append(local_pos);
	local_uvs.append(local_uv);
}
