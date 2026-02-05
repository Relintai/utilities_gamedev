tool;
extends ViewportContainer;

export(NodePath) NodePath container_path;

Node _container;

void _ready() {
	_container = get_node(container_path);
}

void preview(Spatial n) {
	_container.add_child(n);
	n.owner = _container;
}
