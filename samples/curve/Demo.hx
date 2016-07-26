import h2d.Graphics;
import hxd.Stage;


class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	var inter : h2d.Interactive;
	function new() {
		super();
		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xFFCCCCCC;
		hxd.Key.initialize();
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
		
		var curve = new hxd.tools.Catmull1([0,2.5, 3.0, 2.8, 2.45, 2.0, 1.25, 0.6,0]);
		
		var g = new h2d.Graphics(scene);
		g.lineStyle(1.0);
		
		var nb = 100;
		var w = hxd.System.width;
		var h = hxd.System.height;
		var e = 0.001;
		g.addPoint(-e, h);
		for ( i in 0...nb+1) {
			var	x = i / nb;
			var y = curve.plotWhole( x );
			g.addPoint(x * w , h - y * h * 0.25);
			trace(x + " " + y);
		}
		g.addPoint(w + e, h + e);
		
		inter = new h2d.Interactive( w, h, scene); 
		
		inter.onClick = function(e:hxd.Event) {
			var w = hxd.System.width;
			var h = hxd.System.height;
			var p =  new h2d.col.Point(e.relX / w, 1.0 - e.relY / h);
			trace(p);
			curveBuf.push(p);
		}
	}
	
	var c2 : h2d.Graphics;
	var curveBuf : Array<h2d.col.Point>;
	function plot() {
		curveBuf.sort( function(p0, p1) return Reflect.compare(p0.x, p1.x));
		
		trace(curveBuf);
		var curve = new hxd.tools.Catmull2(curveBuf);
		var g = new h2d.Graphics(scene);
		g.lineStyle(1.0);
		
		var nb = 100;
		var w = hxd.System.width;
		var h = hxd.System.height;
		var e = 0.001;
		g.addPoint(-e, h);
		for ( i in 0...nb+1) {
			var	t = i / nb;
			var xy = curve.plotWhole( t );
			g.addPoint(xy.x * w , h - xy.y * h );
		}
		g.addPoint(w  + e, h + e);
		c2 = g;
		trace( curve );
	}
	
	function update() 	{
		scene.checkEvents();
		if ( hxd.Key.isReleased(hxd.Key.L)) {
			curveBuf = [];
			curveBuf.push( new h2d.col.Point(0,0));
		}
		
		if ( hxd.Key.isReleased(hxd.Key.C)) {
			if( c2!=null) c2.dispose();
			plot();
		}
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
