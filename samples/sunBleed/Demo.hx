import h2d.Graphics;
import hxd.Stage;

class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	
	function new() {
		super();
		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xff000000;
		engine.init();
		
	}
	
	function init() {
		hxd.System.setLoop(update);
		scene = new h2d.Scene();
		
		scene = new h2d.Scene();
		
		var light = new h2d.CachedBitmap( scene );
		var g = new h2d.Graphics(light);
		
		g.beginFill(0x0000FF,1.0);
		g.drawRect( 0, 0, 600, 300);
		g.endFill();
		
		g.beginFill(0xFFF57D,1.0);
		g.drawCircle( 100, 100, 50, 50);
		g.endFill();
		
		g.beginFill(0x0,1.0);
		g.drawRect( 120, 120, 50, 250);
		g.endFill();
		
		var bg = new h2d.Graphics();
		bg.beginFill(0x0000FF,1.0);
		bg.drawRect( 0, 0, 600, 300);
		bg.endFill();
		
		bg.beginFill(0xFFF57D,1.0);
		bg.drawCircle( 100, 100, 50, 50);
		bg.endFill();
		
		light.drawToBackBuffer = false;
		
		var rest = new h2d.CachedBitmap( scene );
		var g = new h2d.Graphics(rest);
		g.beginFill(0xFF0000,1.0);
		g.drawRect( 120, 120, 50, 250);
		g.endFill();
		g.beginFill(0xFFAfff,1.0);
		g.drawRect( 0, 300, 600, 300);
		g.endFill();
		rest.drawToBackBuffer = false;
		
		var final = new h2d.CachedBitmap(scene);
		
		final.secondaryMap = light.permaTile;	
		final.setSunBleed( new h3d.Vector(0.2, 0.2), 0.7, 0.5, 0.33,0.89);
		final.drawToBackBuffer = true;
		
		rest.onOffscreenRenderDone = function(tile) {
			final.secondaryMap = light.permaTile;
			final.addChild( bg );
			new h2d.Bitmap( tile,final );
		}
		//final.visible = false;
		
		//bmp.setSunBleed(new h3d.Vector(0.25, 0.25), 1.0, 1.0, 1.0, 0.5);
	}
	
	function update() 	{
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
