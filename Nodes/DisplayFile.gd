extends TextureRect

func setImage(dir: String):
	print(dir)
	var imG = Image.new()
	imG.load(dir)
	var imGReal = ImageTexture.new()
	imGReal.set_image(imG)
	texture = imGReal
