package hxd;

class Pools{

	public static var tiles : Pool<h2d.Tile> = new hxd.Pool<h2d.Tile>(h2d.Tile);

	static var _  = {
		tiles.actives = null;
		tiles.allocProc = function( t){
			t.clear();
		};
	}
}