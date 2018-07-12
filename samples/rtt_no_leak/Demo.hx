import h2d.Graphics;
import hxd.Stage;

class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
		
	function new() {
		super();
		
		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xFFCCCCCC;
		engine.init();
	}
	
	public static inline function timerDelay(func:Void->Void,ms:Int){
		var t = new flash.utils.Timer( ms );
		function named(e){
			func();
			t.removeEventListener( "timer", named );
		}
		t.addEventListener( "timer", named, false,0,false);
		t.start();
	}
	
	function init() {
		
		hxd.System.setLoop(update);
		scene = new h2d.Scene();
		
		for( i in 0...16){
		var bbmp = new h2d.Bitmap( h2d.Tile.fromColor(0xffcdffcd ), scene);
			bbmp.x = 100 + i * 50;
			bbmp.y = 100 + i * 50;
			bbmp.setScale( 50 );
			bbmp.rotation = Math.PI * 0.1;
		}
		
		for( dms in [ 1000, 1000 * 5, 1000 * 10, 1000 * 20, 1000 * 30, 1000 * 60, 1000 * 60 *2, 1000 * 60 * 3, 1000 * 60 * 5,1000 * 60 * 20])
			timerDelay( function(){
				flash.system.System.pauseForGCIfCollectionImminent(1);
				trace( flash.system.System.privateMemory );
		}, dms );
	} 
	
	function update() 	{
		scene.checkEvents();
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
