import h2d.Bitmap;
import h2d.Graphics;
import h2d.Text;
import h2d.Tile;
import h2d.Vector;
import hxd.Key;
import hxd.Stage;

class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
		
	function new() {
		super();
		
		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xFF000000;
		engine.init();
		
		f = openfl.Assets.getFont("assets/nokiafc22.ttf");
		
	}
	public var nokia8 : h2d.Font;
	public var nokia16 : h2d.Font;
	var f:flash.text.Font;
	var sb :h2d.SpriteBatch;
	
	function init() {
		var opt : hxd.res.FontBuilder.FontBuildOptions= { antiAliasing:false};
		nokia16 = hxd.res.FontBuilder.getFont( f.fontName, 16,opt);
		
		hxd.System.setLoop(update);
		scene = new h2d.Scene();
		
		r = new Text(nokia16, scene); 	r.textColor = 0xffffffff; r.x = 30; r.y = 200;
		g = new Text(nokia16,scene);	g.textColor = 0xffffffff; g.x = 30; g.y = 220;
		b = new Text(nokia16, scene);	b.textColor = 0xffffffff; b.x = 30; b.y = 240;
		bmp = new Bitmap(Tile.fromColor(0xFFffFFff), scene);
		bmp.x = 30;
		bmp.y = 30;
		bmp.setSize(100, 100);
		
		r.text = "" + rval;
		g.text = "" + gval;
		b.text = "" + bval;
		
		ChromaSDK.get().init( { supported:Type.allEnums(ChromaSDK.ChromaDevice) } );
		Key.initialize();
	}
	
	var r : Text; var rval = 120;
	var g : Text; var gval = 120;
	var b : Text; var bval = 120;
	var bmp : Bitmap;
	
	function update() 	{
		
		rval = hxd.Math.iclamp(rval, 0, 255);
		gval = hxd.Math.iclamp(gval, 0, 255);
		bval = hxd.Math.iclamp(bval, 0, 255);
		
		if ( Key.isDown(Key.A)) r.text = ""+(rval += 2);
		if ( Key.isDown(Key.Q)) r.text = ""+(rval -= 2);
		if ( Key.isDown(Key.Z)) g.text = ""+(gval += 2);
		if ( Key.isDown(Key.S)) g.text = ""+(gval -= 2);
		if ( Key.isDown(Key.E)) b.text = ""+(bval += 2);
		if ( Key.isDown(Key.D)) b.text = ""+(bval -= 2);
		
		var rgb = (rval << 16) | (gval << 8)  | bval;
		bmp.color = h3d.Vector.fromColor( rgb | (255 << 24) );
		
		var c = ChromaSDK.get();
		if ( c.initialised ) {
			timer -= hxd.Timer.deltaT;
			if ( timer < 0 ) {
				var m = c.getMouse();
				m.color(rgb);
				trace(r + " "+g + " " + b);
				timer = 0.5;
			}
		}
		
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	var timer = 0.5;
	
	static function main() {
		new Demo();
	}
}
