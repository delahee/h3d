
import flash.display.Bitmap;
import h2d.Graphics;
import h2d.Sprite;
import h2d.Text;
import h2d.TileGroup;
import h3d.Engine;
import haxe.Resource;
import haxe.Utf8;
import hxd.BitmapData;
import h2d.SpriteBatch;

class T {
	//public static inline var W = 60;
}

class Demo 
{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	var actions : List < Void->Void > ;
	
	function new() 
	{
		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xFFCCCCCC;
		//engine.autoResize = true;
		engine.init();
		
		#if flash
		flash.Lib.current.addChild(new openfl.display.FPS());
		#end
		//flash.Lib.current.addEventListener(flash.events.Event.RESIZE, onResize );
	}
	
	function onResize(_)
	{
		trace("resize");
		trace(flash.Lib.current.stage.stageWidth + " " + flash.Lib.current.stage.stageHeight);
	}
	
	function init() 
	{
		actions = new List();
		scene = new h2d.Scene();
		
		var root = new h2d.Sprite(scene);
		
		var tileHaxe = hxd.Res.haxe.toTile();
		var tileNME = hxd.Res.nme.toTile();
		var tileOFL = hxd.Res.openfl.toTile();
		
		tileHaxe = tileHaxe.center( Std.int(0), Std.int(0) );
		tileNME = tileNME.center( Std.int(tileNME.width / 2), Std.int(tileNME.height / 2) );
		tileOFL = tileOFL.center( Std.int(tileOFL.width / 2), Std.int(tileOFL.height / 2) );
		
		gfx = new Graphics(scene);
		local = new Sprite(scene);
		
		var font = hxd.res.FontBuilder.getFont("arial", 32, { antiAliasing : false , chars : hxd.Charset.DEFAULT_CHARS } );
		var tf = fps=new h2d.Text(font, local);
		tf.textColor = 0xFFFFFF;
		tf.dropShadow = { dx : 0.5, dy : 0.5, color : 0xFF0000, alpha : 0.8 };
		tf.text = "Hello Héllò h2d àáâã !";
		tf.scale(1);
		tf.y = 100;
		tf.x = 100;
		
		local.rotation = Math.PI / 4 * 0.5;
		bmp = new h2d.Bitmap(tileHaxe, scene);
		bmp.x = 256;
		bmp.y = 128;
		bmp.color = new h3d.Vector(1,1,1,1);
		
		tg = new TileGroup(tileHaxe, scene);
		tg.rotation = Math.PI / 4 * 0.5;
		
		tg.add( 64, 64, tileHaxe);
		tg.add( 256, 128, tileHaxe);
		
		
		layer = new h2d.Layers(scene);
				
		#if false
		var b = new h2d.Bitmap(tileHaxe,layer);
		b.x = 50;              
		b.y = 50;              
		var b = new h2d.Bitmap(tileHaxe,layer);
		b.x = 100;             
		b.y = 50;              
		var b = new h2d.Bitmap(tileHaxe,layer);
		b.x = 50;              
		b.y = 100;             
		var b = new h2d.Bitmap(tileHaxe,layer);
		b.x = 100;
		b.y = 100;
		#end
		
		function make(g) {
			g.beginFill(0x0000FF,0.5);
			g.drawRect(0, 0, 49, 49);
			g.endFill();
		}
		
		var b = new h2d.Graphics(layer);
		b.x = 50;              
		b.y = 50;              
		make(b);
		
		var b = new h2d.Graphics(layer);
		b.x = 100;             
		b.y = 50;              
		make(b);
		var b = new h2d.Graphics(layer);
		b.x = 50;              
		b.y = 100;             
		make(b);
		var b = new h2d.Graphics(layer);
		b.x = 100;
		b.y = 100;
		make(b);
		
		hxd.Key.initialize();
		
		gfxLayer = new h2d.Graphics(scene);
		hxd.System.setLoop(update);
	}
	
	public var gfx:Graphics;
	
	public var gfxLayer:Graphics;
	public var layer:h2d.Layers;
	
	public var bmp:h2d.Bitmap;
	public var tg : TileGroup;
	public var local:h2d.Sprite;
	static var fps : Text;
	var spin = 0;
	var count = 0;
	
	function rand() {
		var a = [fps,local,tg,bmp];
		return	a[Std.random(a.length)];
	}
	
	function update() 
	{
		count++;
		if (spin++ >=5){
			fps.text = Std.string(Engine.getCurrent().fps);
			spin = 0;
		}
		
		if( spin ==0 ){
			gfx.clear();
			gfx.beginFill(0xFFFF00FF,0.4);
			var b = rand().getBounds();
			gfx.addPoint( b.xMin, b.yMin );
			gfx.addPoint( b.xMin, b.yMax );
			gfx.addPoint( b.xMax, b.yMax );
			gfx.addPoint( b.xMax, b.yMin );
			gfx.endFill();
		}
	
		var gfx = gfxLayer;
		gfx.clear();
		gfx.beginFill(0xFFFF00FF,0.4);
		var b = layer.getBounds();
		trace(b);
		gfx.addPoint( b.xMin, b.yMin );
		gfx.addPoint( b.xMin, b.yMax );
		gfx.addPoint( b.xMax, b.yMax );
		gfx.addPoint( b.xMax, b.yMin );
		gfx.endFill();
		
		engine.render(scene);
	}
	
	static function main() 
	{
		hxd.Res.loader = new hxd.res.Loader(hxd.res.EmbedFileSystem.create());
		new Demo();
	}
}
