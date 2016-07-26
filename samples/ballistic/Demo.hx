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
		hxd.Stack.StackTest.test();
	}
	
	function init() {
		hxd.System.setLoop(update);
		scene = new h2d.Scene();
		var g = new h2d.Graphics(scene);
		g.beginFill(0x00FFFF,0.5);
		g.lineStyle(2.0);
		g.drawRect( 0, 0, 50, 50);
		g.endFill();
		
		plot([[0.0, 0.0], [0.5, 0.5], [1.0, 1.0]].map( function(arr) return new h2d.col.Point(arr[0], arr[1]) ));
		
		var w = hxd.System.width;
		var h = hxd.System.height;
		
		var p0 = new h2d.Vector(0, 0);
		var p1 = new h2d.Vector(1.0, 0);
		var g = new h2d.Vector(0,-0.95);
		var t = 1.0;
		var v0 = Ballistic.calcV0ForDest( p0, p1, g, t);
		trace( "v0:"+v0 );
		var buf = [];
		for ( i in 0...w+1) {
			var ct = (i == 0) ? 0 : i / w * t;
			var pos = Ballistic.calcDest(p0, v0, g, ct);
			buf.push( new h2d.Vector( pos.x, pos.y ) );
		}
		trace( buf );
		plot(buf);
	}
	
	var scx = 0.5;
	var scy = 1.0;
	var c : h2d.Graphics;
	function plot(arr:Array<h2d.col.Point>) {
		if ( c != null) c.dispose();
		var g = new h2d.Graphics(scene);
		g.lineStyle(1.0);
		var w = hxd.System.width;
		var h = hxd.System.height;
		var e = 0.001;
		//g.addPoint(-e, h);
		for ( i in 0...arr.length) {
			var p = arr[i];
			g.addPoint(p.x * w * scx, h - p.y * h * scy);
		}
		//g.addPoint(w * scaleX+ e, h + e);
		c = g;
	}
	
	
	function update() 	{
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
