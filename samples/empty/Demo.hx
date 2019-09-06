import h2d.Graphics;
import hxd.Stage;
import h2d.YuvSurface;

class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	var sb : h2d.SpriteBatch;
	
	function new() {
		super();
		
		//hxd.System.debugLevel = 2;
		
		engine = new h3d.Engine();
		
		engine.onReady = init;
		engine.backgroundColor = 0xFFCCCCCC;
		engine.init();
		
	}
	
	function init() {
		hxd.System.setLoop(update,render);
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
		
		var s = new h2d.Simple( scene );
		s.scale(5);
		s.x = 500;
		s.y = 500;
		
		var s = new h2d.Simple( scene );
		s.tile = h2d.Tile.fromColor(0xff7fabaa);
		s.scale( 5 );
		s.x = 500;
		s.y = 400;
		
		
		var s = new h2d.YuvSurface( scene );
		s.texY = h3d.mat.Texture.fromColor(0xff00FF00);
		s.texUV = h3d.mat.Texture.fromColor(0xff00FF00);
		s.scale( 5 );
		s.x = 500;
		s.y = 300;
		
		var t = new h3d.mat.Texture( 18, 6 );
		t.clear(0xffff00ff);
		
		var bmp = new h2d.Bitmap( h2d.Tile.fromTexture(t), scene );
		bmp.x = 550;
		bmp.y = 300;
	}
	
	function update() 	{
		#if cpp 
		flash.Lib.current.invalidate();
		#end
		
		hxd.Timer.update();
		scene.checkEvents();
		
		if(sb!=null)
		for ( e in sb.getElements() ) {
			e.rotation += 0.1;
			var g = h2d.Graphics.fromBounds( sb.getElementBounds(e,scene),scene, 0xff0000,0.1);
			haxe.Timer.delay( g.dispose , 30);
		}
	}
		
	function render(){
		//trace("render");
		#if (lime >= "7.1.1")
		engine.triggerClear = true;
		#end
		
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
