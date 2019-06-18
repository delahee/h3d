package hxd;

class Pools{

	public static var tiles : Pool<h2d.Tile> = new hxd.Pool<h2d.Tile>(h2d.Tile);
	
	
	public static function init(){
		tiles.actives = null;
		
		tiles.allocProc = function(t:h2d.Tile){
			t.clear();
		};
		
		tiles.deleteProc = function(t:h2d.Tile){
			t.clear();
		};
	}
}