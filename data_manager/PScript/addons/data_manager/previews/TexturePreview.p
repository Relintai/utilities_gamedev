tool;
extends TextureRect;

void set_texture(Texture tex) {
	texture = tex;
	
	if tex is PackerImageResource {
		ImageTexture t = ImageTexture.new();
		
		t.create_from_image(tex.data, 0);
		
		texture = t;
	}
}
