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
	var sb :h2d.SpriteBatch;
	
	static function getNumDecomp(v:Int){
		var v:Float = v;
		var vals = new hxd.IntStack();
		
		vals.reset();
		
		if ( v == 0 ){
			vals.push(0);
		}
		else {
			while ( Std.int(v) != 0 ){
				var idx = Std.int(v) % 10;
				vals.push(idx);
				v = v / 10;
			}
		}
		
		vals.reverse();
		trace(vals);
	}
	
	function init() {
		
		getNumDecomp( 150 );
		getNumDecomp( 149 );
		getNumDecomp( 20000 );
		getNumDecomp( 21000 );
		getNumDecomp( 666666666 );
		
		hxd.System.setLoop(update);
		scene = new h2d.Scene();
		
		var g = new h2d.Graphics(scene);
		g.beginFill(0x00FFFF,0.5);
		g.lineStyle(2.0);
		g.drawRect( 0, 0, 50, 50);
		g.endFill();
		
		g.beginFill(0x00FFFF,0.2);
		g.drawRect( 50, 50, 50, 500);
		g.endFill();
		
		var s = new h2d.Sprite(scene );
		s.x = 50;
		s.y = 250;
		s.scaleX = (0.5); 
		s.scaleY = (1.5); 
		
		var t = h2d.Tile.fromColor(0xffcd00cd, 4, 8);
		sb = new h2d.SpriteBatch( t ,s  );
		var e = sb.alloc( t );
		e.setSize (32 , 32 );
		
		var e = sb.alloc( t );
		e.setSize (32 , 32 );
		e.x = 100;
		e.y = 100;
		
		var t = t.centerRatio(0.5, 0.5);
		var e = sb.alloc( t );
		e.setSize (32 , 32 );
		e.x = 200;
		e.y = 100;
		
		var t = t.centerRatio(1, 1);
		var e = sb.alloc( t );
		e.setSize (32 , 32 );
		e.x = 300;
		e.y = 100;
	}
	
	function update() 	{
		
		for ( e in sb.getElements() ) {
			e.rotation += 0.1;
			var g = h2d.Graphics.fromBounds( sb.getElementBounds(e,scene),scene, 0xff0000,0.1);
			haxe.Timer.delay( g.dispose , 30);
		}
		
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
