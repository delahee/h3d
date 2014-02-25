package h2d;

class Bitmap extends Drawable {
	public var tile : Tile;
	
	public function new( ?tile, ?parent ) {
		super(parent);
		this.tile = tile;
	}
	
	override function draw( ctx : RenderContext ) {
		drawTile(ctx.engine,tile);
	}
			
	public static function create( bmp : hxd.BitmapData, ?allocPos : h3d.impl.AllocPos ) {
		return new Bitmap(Tile.fromBitmap(bmp,allocPos));
	}
	
	override function getMyBounds() {
		var m = getPixSpaceMatrix(tile);
		var bounds = h2d.col.Bounds.fromValues(0,0, tile.width,tile.height);
		bounds.transform( m );
		return bounds;
	}
	
}