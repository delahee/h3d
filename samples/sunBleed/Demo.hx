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
		
		//makeBasics();
		makeComplex();
	}
	
	
	function makeComplex() {
		var light = new h2d.CachedBitmap( scene );
		var w = flash.Lib.current.stage.stageWidth;
		var h = flash.Lib.current.stage.stageHeight; 
		
		var showLightPass = false;
		var showOccludersPass = false;
		
		//light pass here
		var b = new h2d.Bitmap( h2d.Tile.fromAssets("assets/sky.png").centerRatio(0.5,0) , light );
		b.x = w * 0.5;
		b.color = new h3d.Vector(1,1,1,2);
		var b = new h2d.Bitmap( h2d.Tile.fromAssets("assets/sun.png").centerRatio(0.5,0) , light );
		b.x = w * 0.5; b.y = h * 0.1;
		b.color = new h3d.Vector(1, 1, 1, 2);
		/*
		var b = new h2d.Bitmap( h2d.Tile.fromAssets("assets/bgRocks.png").centerRatio(0.5,1)	, light );
		b.x = w * 0.5; b.y = h * 0.80;
		b.scale(1.25);
		b.color = new h3d.Vector(1,1,1,2);
		
		var b = new h2d.Bitmap( h2d.Tile.fromAssets("assets/bg.png").centerRatio(0.5,1)	, light );
		b.x = w * 0.5; b.y = h * 0.85;
		b.scale(1.25);
		b.color = new h3d.Vector(1,1,1,1.2);
		*/
		if(!showLightPass)
			light.drawToBackBuffer = false;
		
		var rest = new h2d.CachedBitmap( scene );
		
		var opaqA = 0.7;
		var b = new h2d.Bitmap( h2d.Tile.fromAssets("assets/sky.png").centerRatio(0.5,0) , rest );
		b.x = w * 0.5;
		b.color = new h3d.Vector(1,1,1,opaqA);
		var b = new h2d.Bitmap( h2d.Tile.fromAssets("assets/sun.png").centerRatio(0.5,0) , rest );
		b.x = w * 0.5; b.y = h * 0.1;
		b.color = new h3d.Vector(1,1,1,opaqA);
		var b = new h2d.Bitmap( h2d.Tile.fromAssets("assets/bgRocks.png").centerRatio(0.5,1)	, rest );
		b.x = w * 0.5; b.y = h * 0.80;
		b.color = new h3d.Vector(1,1,1,opaqA);
		b.scale(1.25);
		var b = new h2d.Bitmap( h2d.Tile.fromAssets("assets/bg.png").centerRatio(0.5,1)	, rest );
		b.x = w * 0.5; b.y = h * 0.85;
		b.color = new h3d.Vector(1,1,1,opaqA);
		b.scale(1.25);
		
		rest.drawToBackBuffer = false;
		if( showLightPass ) {
			rest.visible = false;
		}
		
		var final = new h2d.CachedBitmap(scene);
		
		var z = new h2d.Bitmap(h2d.Tile.fromAssets("assets/zombieE_run04.png").centerRatio(0.5, 1.0) );
		z.x = 0.5 * w;
		z.y = 200;
		rest.addChild( z );
		
		final.secondaryMap = light.permaTile;	
		final.setSunBleed( new h3d.Vector(0.39, 0.1),0.8, 0.6, 0.3, 0.95);
		//final.drawToBackBuffer = true;
		rest.onOffscreenRenderDone = function(tile) {
			final.secondaryMap = light.permaTile;
			new h2d.Bitmap( tile, final );
		}
		
		if ( showLightPass || showOccludersPass )
			final.visible = false;
			
		var g = new h2d.Graphics(scene);
		g.lineStyle(1);
		g.beginFill(0xff0000);
		g.drawRect( -2, -2, 4, 4);
		g.endFill();
		
		g.x = 512 * 0.39;
		g.y = 512 * 0.1;
	}
	
	function makeBasics() {
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
		final.setSunBleed( new h3d.Vector(0.1, 0.1), 4,1,1,1);
		//final.drawToBackBuffer = true;
		
		rest.onOffscreenRenderDone = function(tile) {
			final.secondaryMap = light.permaTile;
			final.addChild( bg );
			new h2d.Bitmap( tile,final );
		}
	}
	
	function update() 	{
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
