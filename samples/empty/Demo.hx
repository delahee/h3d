import h2d.Graphics;
import hxd.Stage;


class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	
	public static function bsearchIndex<K,S>( a : Array<S>, key : K, f : K -> S -> Int ) : Int	{
		var st = 0;
		var max = a.length;
		
		var index = - 1;
		while(st < max)	{
			index = ( st + max ) >> 1;
			var val = a[index];
			
			var cmp = f( key, val);
			if( cmp < 0  )
				max = index;
			else if ( cmp > 0)
				st = index + 1;
			else 
				return index;
		}
		
		return
		switch( f( key, a[index])) {
			default:index;
			case 1: index+1;
		}
	}
				
	function new() {
		super();
		
		var a :Array<Float>= [1, 2, 3, 4, 5];
		trace( bsearchIndex(a,  2.5,Reflect.compare));
		trace( bsearchIndex(a,  3.0,Reflect.compare));
		trace( bsearchIndex(a,  6.0, Reflect.compare));
		
		var a :Array<Float>= [1, 2, 5];
		trace( bsearchIndex(a,  2.5,Reflect.compare));
		trace( bsearchIndex(a,  3.0,Reflect.compare));
		trace( bsearchIndex(a,  6.0, Reflect.compare));
		
		var a :Array<Float>= [1, 2,3,3,3, 5];
		trace( bsearchIndex(a,  2.5, Reflect.compare));
		trace( bsearchIndex(a,  5.0,Reflect.compare));
		trace( bsearchIndex(a,  6.0, Reflect.compare));
		
		var a = [];
		for ( k in 0...100) {
			a = [];	
				for ( i in 0...50+Std.random(50)) {
				var b = Math.random()*6;
				a.insert( bsearchIndex(a,b,Reflect.compare), b);
			}
			trace(a);
			for ( i in 0...a.length - 1) {
				if (a[i] > a[i + 1])
					throw "order assert";
			}
		}
		
		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xFFCCCCCC;
		engine.init();
		
	}
	
	function init() {
		hxd.System.setLoop(update);
		scene = new h2d.Scene();
		var g = new h2d.Graphics(scene);
		g.beginFill(0x00FFFF,0.5);
		g.lineStyle(2.0);
		g.drawRect( 0, 0, 50, 50);
		g.endFill();
		
		
		var g = new h2d.Graphics(scene);
		g.beginFill();
		g.addPointFull( 100, 100, 1, 0, 0, 1 );
		g.addPointFull( 200, 100, 0, 1, 0, 0 );
		g.addPointFull( 200, 200, 1, 0, 1, 0.3 );
		g.addPointFull( 100, 200, 1, 1, 0, 1 );
		g.endFill();
	}
	
	function update() 	{
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
