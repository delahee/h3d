import h2d.Graphics;
import hxd.Stage;
import h2d.Tweenie;

class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
		
	function new() {
		super();
		
		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xFFCCCCCC;
		engine.init();
		
		f = openfl.Assets.getFont("assets/nokiafc22.ttf");
		
	}
	public var nokia8 : h2d.Font;
	public var nokia16 : h2d.Font;
	var f:flash.text.Font;
	
	function init() {
		var opt : hxd.res.FontBuilder.FontBuildOptions= { antiAliasing:false};
		nokia16 = hxd.res.FontBuilder.getFont( f.fontName, 16,opt);
		
		hxd.System.setLoop(update);
		scene = new h2d.Scene();
		
		var t = h2d.Tile.fromColor(0xffcd00cd, 32, 32);
		var twhite = h2d.Tile.fromColor(0xFFffFFff, 32, 32);
		
		{
			var bmp = new h2d.Bitmap( t.centerRatio(), scene );
			bmp.x = 979.99;
			bmp.y = 50;
			var t = tw.create(bmp, VX, -100, TLinear, 4000);
		}
		
		{
			var bmp = new h2d.Bitmap( t.centerRatio(), scene );
			bmp.x = 979.99;
			bmp.y = 100;
			var t = twOne.create(bmp, "x", -100, TLinear, 4000);
		}

		if ( false )
		{
			{
				var bmp = new h2d.Bitmap( t.centerRatio(), scene );
				bmp.x = 50;
				bmp.y = 0;
				var t = tw.create(bmp, VY, 1000,TBurn, 1000);
			}
			
			{
				var bmp = new h2d.Bitmap( t.centerRatio(), scene );
				bmp.x = 50;
				bmp.y = 50;
				var t = tw.create(bmp, VScaleX, 2, TShake, 1000);
			}
			
			{
				var bmp = new h2d.Bitmap( t.centerRatio(), scene );
				bmp.x = 100;
				bmp.y = 100;
				var t = tw.create(bmp, VScale, 4.0, TBurn, 1000);
			}
			
			{
				var bmp = new h2d.Bitmap( twhite.centerRatio(), scene );
				bmp.x = 200;
				bmp.y = 200;
				var t = tw.create(bmp, VAlpha, 0.0, TEaseOut, 1000);
			}
			
			{
				var bmp = new h2d.Bitmap( twhite.centerRatio(), scene );
				bmp.x = 250;
				bmp.y = 250;
				var t = tw.create(bmp, VR, 0.0, TEaseOut, 1000);
			}
			
			{
				var bmp = new h2d.Bitmap( twhite.centerRatio(), scene );
				bmp.x = 300;
				bmp.y = 300;
				var t = tw.create(bmp, VG, 0.0, TEaseOut, 1000);
			}
			
			{
				var bmp = new h2d.Bitmap( twhite.centerRatio(), scene );
				bmp.x = 350;
				bmp.y = 350;
				var t = tw.create(bmp, VB, 0.0, TEaseOut, 1000);
			}
		}
	}
	
	var tw = new h2d.Tweenie();
	var twOne = new mt.deepnight.Tweenie();
	
	function update() 	{
		var tmod = 1.0;
		tw.update(tmod);
		twOne.update(tmod);
		
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
