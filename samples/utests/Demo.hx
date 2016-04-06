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
	
	function init() {
		hxd.System.setLoop(update);
		scene = new h2d.Scene();
		var g = new h2d.Graphics(scene);
		g.beginFill(0x00FFFF,0.5);
		g.lineStyle(2.0);
		g.drawRect( 0, 0, 50, 50);
		g.endFill();
		
		var s = new hxd.Stack<Null<Int>>();
		s.push(0);s.push(1);
		s.push(2); s.push(3);
		
		for ( nb in s) {
			trace(nb);
		}
		trace("..");
		for ( nb in s) {
			trace( nb);
			if ( nb == 1 ){
				s.remove( nb );
				trace( "removing" );
			}
		}
		
		trace("...");
		var s = new hxd.Stack<Null<Int>>();
		s.push(0);s.push(1);
		s.push(2); s.push(3);
		for ( nb in s.backWardIterator()) {
			trace(nb);	
		}
		
		s.removeAt( 2 );
		
		for ( nb in s.backWardIterator()) {
			trace( nb);
			if ( nb == 2 ){
				s.remove( nb );
				trace( "removing" );
			}
		}
		
	}
	
	var sd = new hxd.Stack<Null<Int>>();
	function update() 	{
		for( i in 0...4)
			sd.push( i );
			
		for ( nb in sd.backWardIterator()) {
			nb++;
			//if ( nb == null )
			//	throw "error" ;
		}
		
		sd.reset();
		
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
