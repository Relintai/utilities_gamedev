tool
extends Control

enum State {
	STATE_OFF = 0,
	STATE_FLIP_PHASE_1 = 1,
	STATE_FLIP_PHASE_2 = 2,
};

export(Texture) var texture_from : Texture = null
export(Texture) var texture_back : Texture = null
export(bool) var flip : bool = false

var tex_mirror : bool = false
var angle : float = 0

export(bool) var start_flip : bool = false setget set_flip

var _state : int = 0
var mesh : ArrayMesh = ArrayMesh.new()

func start():
	_state = State.STATE_FLIP_PHASE_1
	
	set_process(true)

func _draw() -> void:
	var tex : Texture = null
	
	if flip:
		tex = texture_back
	else:
		tex = texture_from
		
	var tf_top : Transform2D = Transform2D()
	tf_top.x = Vector2(1, 0).rotated(angle)
	var tf_bottom : Transform2D = Transform2D()
	tf_bottom.x = Vector2(1, 0).rotated(-angle)
	
	var arr : Array = Array()
	
	arr.resize(ArrayMesh.ARRAY_MAX)
	
	var rhx : float = rect_size.x / 2
	
	var v : PoolVector2Array = PoolVector2Array()
	v.push_back(tf_top.xform(Vector2(-rhx, 0)) + Vector2(rhx, 0))
	v.push_back(tf_top.xform(Vector2(rhx, 0)) + Vector2(rhx, 0))
	v.push_back(tf_bottom.xform(Vector2(-rhx, rect_size.y)) + Vector2(rhx, 0))
	v.push_back(tf_bottom.xform(Vector2(rhx, rect_size.y)) + Vector2(rhx, 0))
	arr[ArrayMesh.ARRAY_VERTEX] = v
	
	var c : PoolColorArray = PoolColorArray()
	c.push_back(Color(1, 1, 1, 1))
	c.push_back(Color(1, 1, 1, 1))
	c.push_back(Color(1, 1, 1, 1))
	c.push_back(Color(1, 1, 1, 1))
	arr[ArrayMesh.ARRAY_COLOR] = c
	
	if !tex_mirror:
		var uv : PoolVector2Array = PoolVector2Array()
		uv.push_back(Vector2(0, 0))
		uv.push_back(Vector2(1, 0))
		uv.push_back(Vector2(0, 1))
		uv.push_back(Vector2(1, 1))
		arr[ArrayMesh.ARRAY_TEX_UV] = uv
	else:
		var uv : PoolVector2Array = PoolVector2Array()
		uv.push_back(Vector2(1, 0))
		uv.push_back(Vector2(0, 0))
		uv.push_back(Vector2(1, 1))
		uv.push_back(Vector2(0, 1))
		arr[ArrayMesh.ARRAY_TEX_UV] = uv
	
	var indices : PoolIntArray = PoolIntArray()
	indices.push_back(0)
	indices.push_back(1)
	indices.push_back(2)
	indices.push_back(1)
	indices.push_back(2)
	indices.push_back(3)
	arr[ArrayMesh.ARRAY_INDEX] = indices
	
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	
	draw_mesh(mesh, tex, null, Transform2D())

func _process(delta: float) -> void:
	if _state == State.STATE_OFF:
		set_process(false)
	elif _state == State.STATE_FLIP_PHASE_1:
		angle += 0.01
		
		if angle >= PI / 2:
			angle = PI / 2
			_state = State.STATE_FLIP_PHASE_2
			flip = !flip
			tex_mirror = true
		
		update()
	elif _state == State.STATE_FLIP_PHASE_2:
		angle += 0.01
		
		if angle >= PI:
			angle = 0
			_state = State.STATE_FLIP_PHASE_1
			tex_mirror = false
			
			
		update()

func _ready() -> void:
	set_process(false)
	
	start()

func set_flip(val):
	if val:
		start()
