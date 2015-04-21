package hxd.res;

private class SingleFileSystem extends BytesFileSystem {

	var path : String;
	var bytes : haxe.io.Bytes;
	
	public function new(path, bytes) {
		super();
		this.path = path;
		this.bytes = bytes;
	}
	
	override function getBytes(p) {
		return p == path ? bytes : null;
	}
	
}

@:access(hxd.res.Loader)
class Any extends Resource {

	var loader : Loader;
	
	public function new(loader, entry) {
		super(entry);
		this.loader = loader;
	}
	
	public function toModel() {
		return loader.loadModel(entry.path);
	}
	
	public function toFbx() {
		return loader.loadModel(entry.path).toFbx();
	}

	/*
	public function toAwd() {
		return loader.loadAwdModel(entry.path);
	}
	*/

	public function toTexture() {
		return loader.loadTexture(entry.path).toTexture();
	}
	
	public function toTile() {
		return loader.loadTexture(entry.path).toTile();
	}
	
	public override function toString() {
		return entry.getBytes().toString();
	}

	public function toImage() {
		return loader.loadTexture(entry.path);
	}

	public function getTexture() {
		return loader.loadTexture(entry.path);
	}
	
	public function toSound() {
		return loader.loadSound(entry.path);
	}

	public function toFont() {
		return loader.loadFont(entry.path);
	}

	public function toBitmap() {
		return loader.loadTexture(entry.path).toBitmap();
	}

	public function toBitmapFont() {
		return loader.loadBitmapFont(entry.path);
	}
	
	#if tilemap
	public function toTiledMap() {
		return loader.loadTiledMap(entry.path);
	}
	#end
	
	public function toGradients() {
		return loader.loadGradients(entry.path);
	}

	public inline function iterator() {
		return new hxd.impl.ArrayIterator([for( f in entry ) new Any(loader,f)]);
	}
	
	public static function fromBytes( path : String, bytes : haxe.io.Bytes ) {
		var fs = new SingleFileSystem(path,bytes);
		return new Loader(fs).load(path);
	}

}